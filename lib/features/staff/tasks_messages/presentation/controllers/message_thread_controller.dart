import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

/// Initials used for the tiny sender avatar on newly-sent outgoing bubbles,
/// matching the placeholder used by the mocked chat history (see
/// `StaffTasksMessagesRepositoryImpl`).
const String _currentStaffInitials = 'DL';

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
  }

  /// Appends a new outgoing bubble built from the current text field value
  /// to the local mock message list, then clears the input.
  void sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(
      ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        direction: MessageDirection.outgoing,
        timeLabel: _currentTimeLabel(),
        receiptStatus: 'Delivered',
        senderInitials: _currentStaffInitials,
      ),
    );
    textController.clear();
  }

  String _currentTimeLabel() {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  @override
  Future<void> refresh() => loadThread();

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
