import 'package:gems_core/gems_core.dart';

import '../entities/message_thread.dart';
import '../entities/recurring_check_instance.dart';
import '../entities/staff_task.dart';
import '../entities/staff_task_detail.dart';
import '../entities/task_stats.dart';
import '../entities/tasks_messages_overview.dart';

/// Staff Tasks & Messages data contract.
abstract class StaffTasksMessagesRepository {
  /// Loads tasks, stats, conversations, and today's recurring checks.
  Future<Result<TasksMessagesOverview>> getOverview();

  /// `GET /tasks?page=1&limit=50&residenceId=` (staff "My tasks" / same as Postman B5).
  Future<Result<List<StaffTask>>> getMyTasks();

  /// `GET /tasks/stats`
  Future<Result<TaskStats>> getTaskStats();

  /// `GET /tasks/{id}` + `GET /tasks/{id}/notes`
  Future<Result<StaffTaskDetail>> getTaskDetail(String taskId);

  /// `PATCH /tasks/{id}` with `{ "status": "completed" }`
  Future<Result<void>> completeTask(String taskId);

  /// `POST /tasks/{id}/notes`
  Future<Result<void>> addTaskNote({
    required String taskId,
    required String body,
  });

  /// `GET /recurring-checks/instances?from&to&mine=true`
  Future<Result<List<RecurringCheckInstance>>> getMyRecurringChecks();

  /// `PATCH /recurring-checks/instances/{id}`
  Future<Result<void>> updateRecurringCheck({
    required String instanceId,
    required String status,
    String? statusNote,
  });

  /// `GET /training/assignments?staffId=`
  Future<Result<List<Map<String, String>>>> getTrainingAssignments();

  /// `GET /documents?page=1&limit=20`
  Future<Result<List<Map<String, String>>>> getDocuments();

  Future<Result<MessageThread>> getThread(String conversationId);

  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  });

  Future<Result<void>> markConversationRead(String conversationId);
}
