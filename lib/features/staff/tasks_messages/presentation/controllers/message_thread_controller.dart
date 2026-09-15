import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// GetX controller for the Message Details (conversation thread) screen.
///
/// Fresh instance per conversation (`tag: conversationId`) so switching
/// threads never mixes message lists.
class MessageThreadController extends BaseController<MessageThread> {
  final String conversationId;
  final String contactName;
  final StaffTasksMessagesRepository repository;

  MessageThreadController({
    required this.conversationId,
    required this.repository,
    this.contactName = 'Conversation',
  }) {
    loadThread();
  }

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final Rx<MessagePriority> sendPriority = MessagePriority.general.obs;
  final TextEditingController textController = TextEditingController();
  final RxBool isSending = false.obs;

  MessageThread? get thread => state.value.data;

  Future<void> loadThread() async {
    setLoading(true);
    final result = await repository.getThread(
      conversationId: conversationId,
      contactName: contactName,
    );
    result.when(
      success: (data) {
        setSuccess(data);
        messages.assignAll(data.messages);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
    await repository.markConversationRead(conversationId);
  }

  void setSendPriority(MessagePriority priority) {
    sendPriority.value = priority;
  }

  /// Sends with `priority` from [sendPriority] (`general`|`routine`|`high`).
  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;
    final priority = switch (sendPriority.value) {
      MessagePriority.highPriority => 'high',
      MessagePriority.routine => 'routine',
      MessagePriority.general => 'general',
    };
    final result = await repository.sendMessage(
      conversationId: conversationId,
      body: text,
      priority: priority,
    );
    isSending.value = false;
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error,
        fallbackTitle: 'Could not send message',
      );
      return;
    }
    textController.clear();
    await loadThread();
  }

  @override
  Future<void> refresh() => loadThread();

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
