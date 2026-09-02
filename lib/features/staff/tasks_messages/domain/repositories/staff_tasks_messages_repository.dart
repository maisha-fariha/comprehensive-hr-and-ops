import 'package:gems_core/gems_core.dart';

import '../entities/message_thread.dart';
import '../entities/tasks_messages_overview.dart';

/// Contract for fetching the Staff "Tasks & Messages" screen's data: the
/// combined Tasks/Messages list overview, and an individual conversation's
/// full chat thread. The presentation layer only ever depends on this
/// interface, so swapping the mocked [StaffTasksMessagesRepositoryImpl] for
/// a real API-backed implementation later requires no changes above the
/// data layer.
abstract class StaffTasksMessagesRepository {
  Future<Result<TasksMessagesOverview>> getOverview();

  Future<Result<MessageThread>> getThread(String conversationId);

  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  });

  Future<Result<void>> markConversationRead(String conversationId);
}
