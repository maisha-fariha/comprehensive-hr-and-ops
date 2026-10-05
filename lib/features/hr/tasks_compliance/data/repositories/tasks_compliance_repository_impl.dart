import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/create_task_request.dart';
import '../../domain/entities/task_client_option.dart';
import '../../domain/entities/task_residence_option.dart';
import '../../domain/entities/task_shift_option.dart';
import '../../domain/entities/task_staff_option.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import '../../domain/repositories/tasks_compliance_repository.dart';
import '../mappers/tasks_compliance_mapper.dart';

class TasksComplianceRepositoryImpl implements TasksComplianceRepository {
  final AppApiClient _api;
  final UserSession _session;

  TasksComplianceRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<TasksComplianceOverview>> getOverview() async {
    final residenceId = await _resolveResidenceId();
    final residenceQuery = <String, dynamic>{
      if (residenceId != null && residenceId.isNotEmpty) 'residenceId': residenceId,
    };

    // Compliance tab (A12):
    // - GET /compliance/score          → overall % + breakdown
    // - GET /compliance/overview       → Completed / Pending Review / Needs Attention
    // - GET /compliance/checks?…&outstanding=true → checklist
    // - GET /compliance/requirements   → Upcoming Compliance Reviews
    // - GET /compliance/alerts         → Compliance tab alert badge
    final results = await Future.wait([
      _api.get(
        ApiEndpoints.tasksStats,
        query: residenceQuery,
        silent: true,
      ),
      _api.get(
        ApiEndpoints.tasks,
        query: {
          'page': 1,
          'limit': 20,
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.tasksReview,
        query: residenceQuery,
        silent: true,
      ),
      _api.get(
        ApiEndpoints.tasksRecurring,
        query: residenceQuery,
        silent: true,
      ),
      _api.get(
        ApiEndpoints.trainingCertificates,
        query: {
          'expiryStatus': 'expiring',
          'expiringWithinDays': 30,
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(ApiEndpoints.complianceScore, query: residenceQuery, silent: true),
      _api.get(
        ApiEndpoints.complianceOverview,
        query: residenceQuery,
        silent: true,
      ),
      _api.get(
        ApiEndpoints.complianceChecks,
        query: {
          'page': 1,
          'limit': 20,
          'outstanding': true,
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.complianceRequirements,
        query: {
          'page': 1,
          'limit': 20,
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.complianceAlerts,
        query: residenceQuery,
        silent: true,
      ),
      // Corrective tab:
      // - Active: status=open,in_progress
      // - Overdue badge: overdue=true
      // - Recent Resolutions: status=completed
      _api.get(
        ApiEndpoints.complianceCorrectiveActions,
        query: {
          'page': 1,
          'limit': 20,
          'status': 'open,in_progress',
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.complianceCorrectiveActions,
        query: {
          'page': 1,
          'limit': 20,
          'overdue': true,
          ...residenceQuery,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.complianceCorrectiveActions,
        query: {
          'page': 1,
          'limit': 20,
          'status': 'completed',
          ...residenceQuery,
        },
        silent: true,
      ),
    ]);

    final tasks = results[1];
    final stats = results[0];
    if (tasks.isFailure && stats.isFailure) {
      return Result.failure(
        tasks.error ??
            stats.error ??
            const ApiError(message: 'Could not load tasks.'),
      );
    }

    return Result.success(
      TasksComplianceMapper.compose(
        statsBody: stats.isSuccess ? stats.value : null,
        tasksBody: tasks.isSuccess ? tasks.value : null,
        reviewBody: results[2].isSuccess ? results[2].value : null,
        recurringBody: results[3].isSuccess ? results[3].value : null,
        certificatesBody: results[4].isSuccess ? results[4].value : null,
        scoreBody: results[5].isSuccess ? results[5].value : null,
        overviewBody: results[6].isSuccess ? results[6].value : null,
        checksBody: results[7].isSuccess ? results[7].value : null,
        requirementsBody: results[8].isSuccess ? results[8].value : null,
        alertsBody: results[9].isSuccess ? results[9].value : null,
        activeActionsBody: results[10].isSuccess ? results[10].value : null,
        overdueActionsBody: results[11].isSuccess ? results[11].value : null,
        completedActionsBody: results[12].isSuccess ? results[12].value : null,
        residenceName: _session.residenceName,
      ),
    );
  }

  @override
  Future<Result<List<TaskResidenceOption>>> getResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(TasksComplianceMapper.residencesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<TaskClientOption>>> searchClients({
    required String search,
    String? residenceId,
  }) async {
    final trimmed = search.trim();
    if (trimmed.isEmpty) {
      return Result.success(<TaskClientOption>[]);
    }

    final scopedResidence = residenceId?.trim().isNotEmpty == true
        ? residenceId!.trim()
        : _session.residenceId;

    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'search': trimmed,
        'page': 1,
        'limit': 20,
        if (scopedResidence != null && scopedResidence.isNotEmpty)
          'residenceId': scopedResidence,
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(TasksComplianceMapper.clientsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<TaskStaffOption>>> searchStaff({
    required String search,
    String? residenceId,
  }) async {
    final trimmed = search.trim();
    if (trimmed.isEmpty) {
      return Result.success(<TaskStaffOption>[]);
    }

    final scopedResidence = residenceId?.trim().isNotEmpty == true
        ? residenceId!.trim()
        : _session.residenceId;

    // Purpose-built picker: id, name, category — no payslip fields.
    var result = await _api.get(
      ApiEndpoints.staffDirectory,
      query: {
        if (scopedResidence != null && scopedResidence.isNotEmpty)
          'residenceId': scopedResidence,
      },
      silent: true,
    );
    if (result.isFailure) {
      result = await _api.get(
        ApiEndpoints.staff,
        query: {
          'search': trimmed,
          'page': 1,
          'limit': 20,
          if (scopedResidence != null && scopedResidence.isNotEmpty)
            'residenceId': scopedResidence,
        },
        silent: true,
      );
    }
    if (result.isFailure) {
      return Result.failure(
        result.error ?? const ApiError(message: 'Could not search staff.'),
      );
    }

    final needle = trimmed.toLowerCase();
    final matches = TasksComplianceMapper.staffFrom(result.value)
        .where((option) => option.name.toLowerCase().contains(needle))
        .take(20)
        .toList(growable: false);
    return Result.success(matches);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTaskDetail(String taskId) async {
    final id = taskId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing task id.'),
      );
    }
    final result = await _api.get(ApiEndpoints.taskById(id), silent: true);
    return result.when(
      success: (body) async => Result.success(JsonCodec.unwrapMap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTaskNotes(String taskId) async {
    final id = taskId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing task id.'),
      );
    }
    final result = await _api.get(ApiEndpoints.taskNotes(id), silent: true);
    return result.when(
      success: (body) async {
        final rows = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(JsonCodec.asMap)
            .toList();
        return Result.success(rows);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createTask(CreateTaskRequest request) async {
    final title = request.title.trim();
    final residenceId = request.residenceId.trim();
    if (title.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Task title is required.'),
      );
    }
    if (residenceId.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Residence is required.'),
      );
    }

    final base = createTaskBase(request);
    final recurrence = request.recurrence;
    if (recurrence != null) {
      final result = await _api.post(
        ApiEndpoints.tasksRecurring,
        data: recurringTaskBody(base, recurrence),
        silent: true,
        allowQueue: false,
      );
      return result.when(
        success: (_) async => Result.success(null),
        failure: (error) async => Result.failure(error),
      );
    }

    final created = await _api.post(
      ApiEndpoints.tasks,
      data: {
        ...base,
        if (request.shiftId case final shiftId? when shiftId.isNotEmpty)
          'shiftId': shiftId,
        'dueAt': ?request.dueAt?.toUtc().toIso8601String(),
      },
      silent: true,
      allowQueue: false,
    );
    if (created.isFailure) {
      return Result.failure(
        created.error ?? const ApiError(message: 'Could not create task.'),
      );
    }
    final taskId = JsonCodec.string(JsonCodec.unwrapMap(created.value)['id']);
    if (taskId == null) return Result.success(null);

    if (request.assignedStaffIds.isNotEmpty) {
      final assigned = await replaceAssignees(
        taskId: taskId,
        staffIds: request.assignedStaffIds,
      );
      if (assigned.isFailure) return assigned;
    }
    final note = request.notes?.trim() ?? '';
    if (note.isNotEmpty) {
      final noted = await _api.post(
        ApiEndpoints.taskNotes(taskId),
        data: {'body': note},
        silent: true,
        allowQueue: false,
      );
      if (noted.isFailure) {
        return Result.failure(
          noted.error ?? const ApiError(message: 'Could not save the note.'),
        );
      }
    }
    if (request.attachments.isNotEmpty) {
      final evidence = <Map<String, dynamic>>[];
      for (final file in request.attachments) {
        final uploaded = await _upload(file.path, file.name);
        if (uploaded.isFailure) {
          return Result.failure(
            uploaded.error ?? ApiError(message: 'Could not upload ${file.name}.'),
          );
        }
        evidence.add({'url': uploaded.value, 'label': file.name});
      }
      final patched = await _api.patch(
        ApiEndpoints.taskById(taskId),
        data: {'evidence': evidence},
        silent: true,
        allowQueue: false,
      );
      if (patched.isFailure) {
        return Result.failure(
          patched.error ?? const ApiError(message: 'Could not attach documents.'),
        );
      }
    }
    return Result.success(null);
  }

  /// Fields shared by one-off and recurring tasks (the web's `e0`).
  static Map<String, dynamic> createTaskBase(CreateTaskRequest request) {
    String? trimmed(String? value) {
      final t = value?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return {
      'residenceId': request.residenceId.trim(),
      'title': request.title.trim(),
      'taskType': request.taskType,
      'assignedStaffIds': request.assignedStaffIds,
      'priority': request.priority,
      'requiresReview': request.requiresReview,
      'clientId': ?trimmed(request.clientId),
      'roomArea': ?trimmed(request.roomArea),
      'description': ?trimmed(request.description),
      'checklist': [
        for (final step in request.checklist)
          {'label': step.label, 'done': false, 'required': step.required},
      ],
    };
  }

  static Map<String, dynamic> recurringTaskBody(
    Map<String, dynamic> base,
    TaskRecurrence recurrence,
  ) {
    return {
      ...base,
      'rotateAssignees': recurrence.rotating,
      'frequency': recurrence.frequency,
      'timesOfDay': [recurrence.timeOfDayMinutes],
      if (recurrence.frequency == 'weekly') 'weekdays': recurrence.weekdays,
      if (recurrence.frequency == 'monthly') 'dayOfMonth': recurrence.dayOfMonth,
      if (recurrence.endsOn case final endsOn?)
        'expiresAt': DateTime.utc(endsOn.year, endsOn.month, endsOn.day)
            .toIso8601String(),
    };
  }

  Future<Result<String>> _upload(String localPath, String fileName) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: {'category': 'tasks'},
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(map['fileUrl'] ?? map['url']);
          return url == null
              ? Result.failure(
                  const ApiError(message: 'Upload succeeded but file URL was missing.'),
                )
              : Result.success(url);
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(ApiError(message: 'Could not upload $fileName: $error'));
    }
  }

  @override
  Future<Result<List<String>>> getRooms(String residenceId) async {
    final result = await _api.get(
      ApiEndpoints.residenceRooms(residenceId),
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(TasksComplianceMapper.roomNamesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<TaskShiftOption>>> getShiftOptions(
    String residenceId,
  ) async {
    final now = DateTime.now().toUtc();
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        'residenceId': residenceId,
        'limit': 50,
        'from': now.subtract(const Duration(days: 1)).toIso8601String(),
        'to': now.add(const Duration(days: 7)).toIso8601String(),
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(TasksComplianceMapper.shiftOptionsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> replaceAssignees({
    required String taskId,
    required List<String> staffIds,
  }) async {
    final id = taskId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing task id.'),
      );
    }
    final result = await _api.put(
      ApiEndpoints.taskAssignees(id),
      data: {'staffIds': staffIds},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reviewTask({
    required String taskId,
    required String decision,
    String? reviewNotes,
  }) async {
    final id = taskId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing task id.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.taskReview(id),
      data: {
        'decision': decision,
        if (reviewNotes != null && reviewNotes.trim().isNotEmpty)
          'reviewNotes': reviewNotes.trim(),
      },
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> pauseRecurring(String recurrenceId) async {
    final id = recurrenceId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing recurrence id.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.taskRecurringPause(id),
      data: const <String, dynamic>{},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> resumeRecurring(String recurrenceId) async {
    final id = recurrenceId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing recurrence id.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.taskRecurringResume(id),
      data: const <String, dynamic>{},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<String?> _resolveResidenceId() async {
    final sessionId = _session.residenceId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) return sessionId;

    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (result.isFailure) return null;

    final rows = JsonCodec.unwrapList(result.value);
    for (final row in rows) {
      if (row is! Map) continue;
      final map = JsonCodec.asMap(row);
      final id = JsonCodec.string(map['id'] ?? map['residenceId'])?.trim();
      if (id == null || id.isEmpty) continue;
      final name = JsonCodec.string(map['name'] ?? map['residenceName']);
      _session.applyStaffContext(residenceId: id, residenceName: name);
      return id;
    }
    return null;
  }
}
