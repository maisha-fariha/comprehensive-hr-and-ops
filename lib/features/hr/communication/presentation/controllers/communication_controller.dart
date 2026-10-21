import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';
import '../../domain/entities/hr_message_contact.dart';
import '../../domain/repositories/communication_repository.dart';

/// GetX controller for Communication (web parity).
class CommunicationController extends BaseController<List<HrConversation>> {
  final CommunicationRepository repository;

  CommunicationController({required this.repository}) {
    loadConversations();
    loadContacts();
    loadResidences();
    loadClients();
  }

  final selectedTab = CommunicationTab.messages.obs;
  final monitoring = false.obs;
  final showingArchived = false.obs;
  final selectedFilter = ConversationFilter.all.obs;
  final searchQuery = ''.obs;
  final selectedConversationId = RxnString();
  final draftText = ''.obs;
  final isSending = false.obs;
  final isStarting = false.obs;
  final isLoadingMessages = false.obs;
  final isLoadingContacts = false.obs;
  final contacts = <HrMessageContact>[].obs;
  final residences = <CommunicationResidenceOption>[].obs;
  final clients = <CommunicationClientOption>[].obs;
  final activeMessages = <HrChatMessage>[].obs;

  late final TextEditingController searchController;
  late final TextEditingController messageController;

  List<HrConversation> get conversations => state.value.data ?? const [];

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    messageController = TextEditingController();
  }

  @override
  void onClose() {
    searchController.dispose();
    messageController.dispose();
    super.onClose();
  }

  List<HrConversation> get filteredConversations {
    final query = searchQuery.value.trim().toLowerCase();
    return conversations.where((conversation) {
      final matchesFilter = selectedFilter.value == ConversationFilter.all ||
          conversation.kind == selectedFilter.value;
      final matchesQuery = query.isEmpty ||
          conversation.title.toLowerCase().contains(query) ||
          conversation.preview.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  HrConversation? get selectedConversation {
    final id = selectedConversationId.value;
    if (id == null) return null;
    for (final conversation in conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  int get activeCount =>
      conversations.where((conversation) => conversation.isActive).length;

  int get unreadCount => conversations.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadCount,
      );

  void selectTab(CommunicationTab tab) {
    selectedTab.value = tab;
    if (tab == CommunicationTab.messages || tab == CommunicationTab.monitoring) {
      monitoring.value = tab == CommunicationTab.monitoring;
      showingArchived.value = false;
      loadConversations();
    }
  }

  void toggleArchived() {
    showingArchived.value = !showingArchived.value;
    selectedConversationId.value = null;
    activeMessages.clear();
    loadConversations();
  }

  void selectFilter(ConversationFilter filter) => selectedFilter.value = filter;

  void onSearchChanged(String value) => searchQuery.value = value;

  Future<void> loadConversations() async {
    setLoading(true);
    final result = await repository.getConversations(
      monitor: monitoring.value,
      archived: showingArchived.value,
    );
    result.when(
      success: (items) {
        setSuccess(items);
        final selected = selectedConversationId.value;
        if (selected != null &&
            items.every((conversation) => conversation.id != selected)) {
          selectedConversationId.value = null;
          activeMessages.clear();
        } else if (selected != null) {
          _clearUnreadLocally(selected);
          repository.markThreadRead(selected);
          loadMessages(selected);
        }
      },
      failure: (error) {
        setError(error.message);
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load conversations',
        );
      },
    );
    setLoading(false);
  }

  Future<void> loadContacts() async {
    isLoadingContacts.value = true;
    final result = await repository.getContacts();
    result.when(
      success: (items) => contacts.assignAll(items),
      failure: (_) {},
    );
    isLoadingContacts.value = false;
  }

  Future<void> loadResidences() async {
    final result = await repository.getResidences();
    result.when(
      success: (items) => residences.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> loadClients() async {
    final result = await repository.getClients();
    result.when(
      success: (items) => clients.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> selectConversation(String id) async {
    final alreadyOpen = selectedConversationId.value == id;
    selectedConversationId.value = id;
    // Drop the previous thread before the next screen builds, so chat B
    // never paints chat A's messages while its own request is in flight.
    if (!alreadyOpen) {
      activeMessages.clear();
      messageController.clear();
      draftText.value = '';
      isLoadingMessages.value = true;
    }
    // Drop the badge as soon as the thread is open. The web does the same
    // with POST /conversations/:id/read, including when the row is tapped
    // again after the list reloads.
    _clearUnreadLocally(id);
    if (!alreadyOpen) await loadMessages(id);
    await repository.markThreadRead(id);
  }

  Future<void> loadMessages(String conversationId) async {
    isLoadingMessages.value = true;
    final result = await repository.getMessages(conversationId);
    result.when(
      success: (messages) {
        if (selectedConversationId.value == conversationId) {
          activeMessages.assignAll(messages);
        }
      },
      failure: (error) {
        if (selectedConversationId.value == conversationId) {
          activeMessages.clear();
          AppErrorDialog.showResultError(
            error,
            fallbackTitle: 'Could not load messages',
          );
        }
      },
    );
    if (selectedConversationId.value == conversationId) {
      isLoadingMessages.value = false;
    }
  }

  bool get canWriteMessages {
    if (!Get.isRegistered<UserSession>()) return true;
    return Get.find<UserSession>().can('messaging:write');
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending.value || !canWriteMessages) return;
    final id = selectedConversationId.value;
    if (id == null) return;

    isSending.value = true;
    final result = await repository.sendMessage(
      conversationId: id,
      body: text,
    );
    result.when(
      success: (message) {
        activeMessages.add(message);
        messageController.clear();
        draftText.value = '';
        _patchConversationPreview(id, message.text);
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not send message',
        );
      },
    );
    isSending.value = false;
  }

  /// Returns the new thread id, or null when the server rejected it.
  Future<String?> startConversation({
    required ConversationCreateType type,
    List<String> memberUserIds = const [],
    String? title,
    String? residenceId,
    String? clientId,
    String firstMessage = '',
  }) async {
    if (isStarting.value) return null;

    isStarting.value = true;
    final result = await repository.startConversation(
      type: type,
      memberUserIds: memberUserIds,
      title: title,
      residenceId: residenceId,
      clientId: clientId,
    );

    final createdId = await result.when<Future<String?>>(
      success: (conversation) async {
        final existing = List<HrConversation>.from(conversations);
        existing.removeWhere((item) => item.id == conversation.id);
        existing.insert(0, conversation);
        setSuccess(existing);
        selectedFilter.value = ConversationFilter.all;
        selectedTab.value = CommunicationTab.messages;
        selectedConversationId.value = conversation.id;
        activeMessages.clear();

        final messageText = firstMessage.trim();
        if (messageText.isNotEmpty) {
          final sent = await repository.sendMessage(
            conversationId: conversation.id,
            body: messageText,
          );
          sent.when(
            success: (message) {
              activeMessages.assignAll([message]);
              _patchConversationPreview(conversation.id, message.text);
            },
            failure: (error) {
              AppErrorDialog.showResultError(
                error,
                fallbackTitle: 'Conversation created, but message failed',
              );
            },
          );
        }

        AppSnackbar.show('Conversation started', conversation.title);
        return conversation.id;
      },
      failure: (error) async {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not start conversation',
        );
        return null;
      },
    );
    isStarting.value = false;
    return createdId;
  }

  /// Family contacts for one resident (`GET /conversations/contacts?clientId=`).
  Future<List<HrMessageContact>> familyContactsFor(String clientId) async {
    final result = await repository.getContacts(clientId: clientId);
    return result.when(
      success: (contacts) => contacts,
      failure: (_) => const [],
    );
  }

  /// Puts an archived thread back in the inbox (`archived: false`).
  Future<void> unarchiveConversation() async {
    final id = selectedConversationId.value;
    if (id == null) return;
    final result = await repository.updateConversation(
      conversationId: id,
      archived: false,
    );
    result.when(
      success: (_) {
        setSuccess(conversations.where((item) => item.id != id).toList());
        selectedConversationId.value = null;
        activeMessages.clear();
        AppSnackbar.show('Conversation restored', '');
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not restore conversation',
      ),
    );
  }

  /// Web header action: archive the open thread so it leaves the list.
  Future<void> hideConversation() async {
    final id = selectedConversationId.value;
    if (id == null) return;
    final result = await repository.updateConversation(
      conversationId: id,
      archived: true,
    );
    result.when(
      success: (_) {
        setSuccess(conversations.where((item) => item.id != id).toList());
        selectedConversationId.value = null;
        activeMessages.clear();
        AppSnackbar.show('Conversation hidden', '');
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not hide conversation',
      ),
    );
  }

  Future<bool> addParticipants(List<String> memberUserIds) async {
    final id = selectedConversationId.value;
    if (id == null || memberUserIds.isEmpty) return false;
    final result = await repository.addMembers(
      conversationId: id,
      memberUserIds: memberUserIds,
    );
    var added = false;
    result.when(
      success: (_) {
        added = true;
        AppSnackbar.show('Participant added', '');
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not add participant',
      ),
    );
    if (added) await loadConversations();
    return added;
  }

  Future<void> markAllRead() async {
    final result = await repository.markAllRead();
    result.when(
      success: (_) {
        final updated = conversations
            .map((conversation) => conversation.copyWith(unreadCount: 0))
            .toList();
        setSuccess(updated);
        AppSnackbar.show('All caught up', 'Conversations marked as read.');
      },
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not mark conversations read',
        );
      },
    );
  }

  void _clearUnreadLocally(String id) {
    final updated = conversations.map((conversation) {
      if (conversation.id != id) return conversation;
      return conversation.copyWith(unreadCount: 0);
    }).toList();
    setSuccess(updated);
  }

  void _patchConversationPreview(String id, String preview) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final updated = conversations.map((conversation) {
      if (conversation.id != id) return conversation;
      return conversation.copyWith(
        preview: preview,
        dateLabel: dateLabel,
        unreadCount: 0,
        isActive: true,
      );
    }).toList();
    setSuccess(updated);
  }

  Future<void> refreshConversations() => loadConversations();

  String? get preferredResidenceId {
    try {
      return Get.find<UserSession>().residenceId;
    } catch (_) {
      return null;
    }
  }
}
