import 'package:gems_core/gems_core.dart';

import '../entities/create_task_request.dart';
import '../entities/task_client_option.dart';
import '../entities/task_residence_option.dart';
import '../entities/task_shift_option.dart';
import '../entities/task_staff_option.dart';
import '../entities/tasks_compliance_overview.dart';

/// Contract for the Tasks & Compliance screen and Tasks-tab write actions.
abstract class TasksComplianceRepository {
  Future<Result<TasksComplianceOverview>> getOverview();

  Future<Result<List<TaskResidenceOption>>> getResidences();

  /// `GET /residences/{id}/rooms` — room names for "Room / Area".
  Future<Result<List<String>>> getRooms(String residenceId);

  /// Non-cancelled shifts at the residence from a day ago to a week ahead,
  /// soonest first — the web's "Shift" options.
  Future<Result<List<TaskShiftOption>>> getShiftOptions(String residenceId);

  /// Typeahead for Create Task "Resident (Optional)" via `GET /clients?search=`.
  Future<Result<List<TaskClientOption>>> searchClients({
    required String search,
    String? residenceId,
  });

  /// Typeahead for Create Task "Assigned Staff" via `GET /staff/directory`.
  Future<Result<List<TaskStaffOption>>> searchStaff({
    required String search,
    String? residenceId,
  });

  /// `GET /tasks/{taskId}`
  Future<Result<Map<String, dynamic>>> getTaskDetail(String taskId);

  /// `GET /tasks/{taskId}/notes`
  Future<Result<List<Map<String, dynamic>>>> getTaskNotes(String taskId);

  /// `POST /tasks/recurring` for a recurrence; otherwise `POST /tasks`, then
  /// assignees, the note and uploaded documents, as the web does.
  Future<Result<void>> createTask(CreateTaskRequest request);

  /// `PUT /tasks/{taskId}/assignees`
  Future<Result<void>> replaceAssignees({
    required String taskId,
    required List<String> staffIds,
  });

  /// `POST /tasks/{taskId}/review`
  Future<Result<void>> reviewTask({
    required String taskId,
    required String decision,
    String? reviewNotes,
  });

  /// `POST /tasks/recurring/{id}/pause`
  Future<Result<void>> pauseRecurring(String recurrenceId);

  /// `POST /tasks/recurring/{id}/resume`
  Future<Result<void>> resumeRecurring(String recurrenceId);
}
