import 'package:gems_core/gems_core.dart';

import '../entities/conversation_preview.dart';
import '../entities/message_contact.dart';
import '../entities/message_thread.dart';
import '../entities/recurring_check_instance.dart';
import '../entities/recurring_check_schedule.dart';
import '../entities/staff_task.dart';
import '../entities/staff_task_detail.dart';
import '../entities/task_creation_options.dart';
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

  /// API-backed options for the staff task creation form.
  Future<Result<TaskCreationOptions>> getTaskCreationOptions();

  /// Rooms for a residence (`GET /residences/{id}/rooms`).
  Future<Result<List<TaskCreationOption>>> getTaskRooms(String residenceId);

  /// Clients for a residence (`GET /clients?residenceId=`).
  Future<Result<List<TaskCreationOption>>> getTaskClients(String residenceId);

  /// Shifts for a residence (`GET /shifts?residenceId=`).
  Future<Result<List<TaskCreationOption>>> getTaskShifts(String residenceId);

  /// `POST /tasks` or `POST /tasks/recurring` when [isRecurring] is true.
  Future<Result<void>> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueAt,
    String taskType = 'administrative',
    String? shiftId,
    required String residenceId,
    List<String> assignedStaffIds = const [],
    String? clientId,
    String? roomArea,
    List<Map<String, dynamic>> checklist = const [],
    bool requiresReview = false,
    String? notes,
    bool isRecurring = false,
    String recurrenceFrequency = 'daily',
    int? recurrenceIntervalMinutes,
    List<int> recurrenceTimesOfDay = const [],
  });

  /// `POST /tasks/{id}/notes`
  Future<Result<void>> addTaskNote({
    required String taskId,
    required String body,
  });

  /// `GET /recurring-checks/instances` for pending/actionable checks.
  Future<Result<List<RecurringCheckInstance>>> getMyRecurringChecks();

  /// `GET /recurring-checks/schedules`
  Future<Result<List<RecurringCheckSchedule>>> getRecurringCheckSchedules();

  /// `GET /recurring-checks/instances?from&to&status&residenceId&mine`
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckInstances({
    DateTime? from,
    DateTime? to,
    String? status,
    String? residenceId,
    bool mine = false,
  });

  /// `PATCH /recurring-checks/instances/{id}`
  Future<Result<void>> updateRecurringCheck({
    required String instanceId,
    required String status,
    String? statusNote,
  });

  /// `POST /recurring-checks/schedules`
  Future<Result<void>> createRecurringCheckSchedule({
    required String residenceId,
    required String clientId,
    required String name,
    String checkType,
    String? instructions,
    String frequency,
    int intervalMinutes,
    String? activeFromMinute,
    String? activeToMinute,
    DateTime? effectiveFrom,
    DateTime? expiresAt,
    bool alertEnabled,
    String? assignedRole,
    String? assignedStaffId,
  });

  /// `PATCH /recurring-checks/schedules/{id}`
  Future<Result<void>> updateRecurringCheckSchedule({
    required String scheduleId,
    required Map<String, dynamic> fields,
  });

  /// `DELETE /recurring-checks/schedules/{id}`
  Future<Result<void>> deleteRecurringCheckSchedule(String scheduleId);

  /// `POST /recurring-checks/entries`
  Future<Result<void>> recordRecurringCheckProgress({
    required String clientId,
    required String residenceId,
    required String note,
    String checkName = 'Welfare observation',
    String outcome = 'normal',
    String? scheduleId,
  });

  /// `GET /recurring-checks/entries`
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckEntries({
    String? residenceId,
    DateTime? from,
    DateTime? to,
  });

  /// `GET /training/assignments?staffId=`
  Future<Result<List<Map<String, String>>>> getTrainingAssignments();

  /// `GET /documents?page=1&limit=20`
  Future<Result<List<Map<String, String>>>> getDocuments();

  /// `GET /conversations`
  Future<Result<List<ConversationPreview>>> getConversations();

  /// `GET /conversations/contacts`
  Future<Result<List<MessageContact>>> getContacts();

  /// `POST /conversations`
  Future<Result<ConversationPreview>> startConversation({
    required String title,
    required List<String> memberUserIds,
  });

  /// `GET /conversations/{id}/messages`
  Future<Result<MessageThread>> getThread({
    required String conversationId,
    String? contactName,
  });

  /// `POST /conversations/{id}/messages` with `priority` (`general`|`routine`|`high`).
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  });

  /// `POST /conversations/{id}/read`
  Future<Result<void>> markConversationRead(String conversationId);

  /// `POST /conversations/read-all`
  Future<Result<void>> markAllConversationsRead();
}
