import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';

/// Local UI state for the HR Communication screen (Messages tab).
class CommunicationController extends GetxController {
  final selectedTab = CommunicationTab.messages.obs;
  final selectedFilter = ConversationFilter.all.obs;
  final searchQuery = ''.obs;
  final selectedConversationId = RxnString();
  final draftText = ''.obs;

  late final TextEditingController searchController;
  late final TextEditingController messageController;

  final List<HrConversation> _conversations = [
    const HrConversation(
      id: 'elm-day',
      title: 'Elm House — day shift',
      preview: 'hi',
      dateLabel: '28/08/2026',
      subtitle: 'Residence group · 3 people',
      kind: ConversationFilter.group,
      memberCount: 3,
      unreadCount: 0,
      isActive: true,
      isGroup: true,
    ),
    const HrConversation(
      id: 'maya-direct',
      title: 'Maya Rahman',
      preview: 'Can you cover tomorrow morning?',
      dateLabel: '27/08/2026',
      subtitle: 'Direct message',
      kind: ConversationFilter.direct,
      memberCount: 2,
      unreadCount: 1,
      isActive: true,
      isGroup: false,
    ),
    const HrConversation(
      id: 'family-ayaan',
      title: 'Ayaan — family',
      preview: 'Thank you for the update.',
      dateLabel: '26/08/2026',
      subtitle: 'Family channel · 4 people',
      kind: ConversationFilter.family,
      memberCount: 4,
      unreadCount: 0,
      isActive: false,
      isGroup: true,
    ),
  ];

  /// Bumps when the conversation list changes so Obx rebuilds.
  final listVersion = 0.obs;

  final Map<String, List<HrChatMessage>> _threads = {
    'elm-day': const [
      HrChatMessage(
        id: 'm1',
        senderName: 'Maya Rahman',
        senderInitials: 'MR',
        text:
            'Handover at 14:00 today — the district nurse is visiting Ayaan first.',
        timeLabel: '15:33',
        direction: ChatMessageDirection.incoming,
      ),
      HrChatMessage(
        id: 'm2',
        senderName: 'Tenant Admin',
        senderInitials: 'TA',
        text: 'hello',
        timeLabel: '01:11',
        direction: ChatMessageDirection.outgoing,
      ),
      HrChatMessage(
        id: 'm3',
        senderName: 'Tenant Admin',
        senderInitials: 'TA',
        text: 'hi',
        timeLabel: '01:11',
        direction: ChatMessageDirection.outgoing,
      ),
    ],
    'maya-direct': const [
      HrChatMessage(
        id: 'd1',
        senderName: 'Maya Rahman',
        senderInitials: 'MR',
        text: 'Can you cover tomorrow morning?',
        timeLabel: '18:20',
        direction: ChatMessageDirection.incoming,
      ),
    ],
    'family-ayaan': const [
      HrChatMessage(
        id: 'f1',
        senderName: 'Nusrat Khan',
        senderInitials: 'NK',
        text: 'Thank you for the update.',
        timeLabel: '11:05',
        direction: ChatMessageDirection.incoming,
      ),
    ],
  };

  final RxList<HrChatMessage> activeMessages = <HrChatMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    messageController = TextEditingController();
    selectedConversationId.value = _conversations.first.id;
    _loadActiveMessages();
  }

  @override
  void onClose() {
    searchController.dispose();
    messageController.dispose();
    super.onClose();
  }

  List<HrConversation> get filteredConversations {
    listVersion.value; // dependency for Obx
    final query = searchQuery.value.trim().toLowerCase();
    return _conversations.where((conversation) {
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
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  int get activeCount =>
      _conversations.where((conversation) => conversation.isActive).length;

  int get unreadCount => _conversations.fold<int>(
        0,
        (sum, conversation) => sum + conversation.unreadCount,
      );

  void selectTab(CommunicationTab tab) => selectedTab.value = tab;

  void selectFilter(ConversationFilter filter) => selectedFilter.value = filter;

  void onSearchChanged(String value) => searchQuery.value = value;

  void selectConversation(String id) {
    selectedConversationId.value = id;
    _loadActiveMessages();
  }

  void _loadActiveMessages() {
    final id = selectedConversationId.value;
    activeMessages.assignAll(_threads[id] ?? const []);
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final id = selectedConversationId.value;
    if (id == null) return;

    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final message = HrChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'Tenant Admin',
      senderInitials: 'TA',
      text: text,
      timeLabel: '$hour:$minute',
      direction: ChatMessageDirection.outgoing,
    );
    final existing = List<HrChatMessage>.from(_threads[id] ?? const []);
    existing.add(message);
    _threads[id] = existing;
    activeMessages.add(message);
    messageController.clear();
    draftText.value = '';
  }

  void startConversation({
    required ConversationFilter type,
    required String recipient,
    String firstMessage = '',
  }) {
    final trimmedRecipient = recipient.trim();
    if (trimmedRecipient.isEmpty) return;

    final id = 'new-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final isGroup = type != ConversationFilter.direct;
    final subtitle = switch (type) {
      ConversationFilter.direct => 'Direct message',
      ConversationFilter.group => 'Residence group',
      ConversationFilter.family => 'Family channel',
      ConversationFilter.all => 'Conversation',
    };

    _conversations.insert(
      0,
      HrConversation(
        id: id,
        title: trimmedRecipient,
        preview: firstMessage.trim().isEmpty ? 'New conversation' : firstMessage.trim(),
        dateLabel: dateLabel,
        subtitle: subtitle,
        kind: type == ConversationFilter.all ? ConversationFilter.direct : type,
        memberCount: isGroup ? 3 : 2,
        unreadCount: 0,
        isActive: true,
        isGroup: isGroup,
      ),
    );

    final messages = <HrChatMessage>[];
    if (firstMessage.trim().isNotEmpty) {
      final time = TimeOfDay.now();
      messages.add(
        HrChatMessage(
          id: '$id-first',
          senderName: 'Tenant Admin',
          senderInitials: 'TA',
          text: firstMessage.trim(),
          timeLabel:
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          direction: ChatMessageDirection.outgoing,
        ),
      );
    }
    _threads[id] = messages;
    selectedFilter.value = ConversationFilter.all;
    selectedTab.value = CommunicationTab.messages;
    selectedConversationId.value = id;
    activeMessages.assignAll(messages);
    listVersion.value++;
  }
}
