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

  void selectTab(CommunicationTab tab) => selectedTab.value = tab;

  void selectFilter(ConversationFilter filter) => selectedFilter.value = filter;

  void onSearchChanged(String value) => searchQuery.value = value;

  Future<void> loadConversations() async {
    setLoading(true);
    final result = await repository.getConversations();
    result.when(
      success: (items) {
        setSuccess(items);
        final selected = selectedConversationId.value;
        if (selected != null &&
            items.every((conversation) => conversation.id != selected)) {
          selectedConversationId.value = null;
          activeMessages.clear();
        } else if (selected != null) {
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
    if (selectedConversationId.value == id) return;
    selectedConversationId.value = id;
    await loadMessages(id);
    await repository.markThreadRead(id);
    _clearUnreadLocally(id);
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
    isLoadingMessages.value = false;
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending.value) return;
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

  Future<void> startConversation({
    required ConversationCreateType type,
    List<String> memberUserIds = const [],
    String? title,
    String? residenceId,
    String? clientId,
    String firstMessage = '',
  }) async {
    if (isStarting.value) return;

    isStarting.value = true;
    final result = await repository.startConversation(
      type: type,
      memberUserIds: memberUserIds,
      title: title,
      residenceId: residenceId,
      clientId: clientId,
    );

    await result.when(
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
      },
      failure: (error) async {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not start conversation',
        );
      },
    );
    isStarting.value = false;
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
