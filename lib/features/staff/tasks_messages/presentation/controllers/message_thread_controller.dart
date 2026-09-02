import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// GetX controller for the Message Details (conversation thread) screen.
///
/// Unlike [TasksMessagesController] this is **not** a shared singleton: a
/// fresh instance is created per conversation (see `MessageThreadPage`,
/// which does `Get.put(MessageThreadController(...), tag: conversationId)`)
/// so switching between conversations never mixes up message lists.
class MessageThreadController extends BaseController<MessageThread> {
  final String conversationId;
  final StaffTasksMessagesRepository repository;

  MessageThreadController({required this.conversationId, required this.repository}) {
    loadThread();
  }

  /// Local, mutable copy of the thread's messages. Seeded from the loaded
  /// [MessageThread] and appended to locally when the user taps send -
  /// there is no backend to persist sent messages to.
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  final TextEditingController textController = TextEditingController();

  MessageThread? get thread => state.value.data;

  Future<void> loadThread() async {
    setLoading(true);
    final result = await repository.getThread(conversationId);
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

  /// Sends the current text field value with `priority: general`.
  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    final result = await repository.sendMessage(
      conversationId: conversationId,
      body: text,
    );
    if (result.isFailure) {
      Get.snackbar(
        'Could not send message',
        result.error?.message ?? 'Request failed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
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
