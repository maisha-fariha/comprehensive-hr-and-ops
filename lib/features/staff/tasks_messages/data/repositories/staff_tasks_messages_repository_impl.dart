import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/message_contact.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/recurring_check_instance.dart';
import '../../domain/entities/recurring_check_schedule.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/staff_task_detail.dart';
import '../../domain/entities/task_creation_options.dart';
import '../../domain/entities/task_stats.dart';
import '../../domain/entities/tasks_messages_overview.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../mappers/staff_tasks_messages_mapper.dart';

class StaffTasksMessagesRepositoryImpl implements StaffTasksMessagesRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffTasksMessagesRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  }) : _api = api,
        _session = session;

  @override
  Future<Result<TasksMessagesOverview>> getOverview() async {
    final results = await Future.wait([
      getMyTasks(),
      getTaskStats(),
      _api.get(ApiEndpoints.conversations, silent: true),
      getMyRecurringChecks(),
    ]);

    final tasksResult = results[0];
    if (tasksResult.isFailure) {
      return Result.failure(
        tasksResult.error ?? const ApiError(message: 'Could not load tasks.'),
      );
    }

    final tasks = tasksResult.value ?? const <StaffTask>[];
    final statsResult = results[1];
    final conversationsResult = results[2];
    final recurringResult = results[3];

    final conversations = conversationsResult.isSuccess
        ? JsonCodec.unwrapList(conversationsResult.value)
              .whereType<Map>()
              .map(
                (item) => StaffTasksMessagesMapper.conversationFrom(
                  JsonCodec.asMap(item),
                  currentUserId: _session.userId,
                ),
              )
              .toList()
        : const <ConversationPreview>[];

    // Prefer counts from the loaded task list so chips always match rows.
    // Fall back to /tasks/stats when the list is empty (e.g. offline cache miss).
    final listStats = StaffTasksMessagesMapper.statsFromTasks(tasks);
    final apiStats = statsResult.isSuccess
        ? (statsResult.value ?? const TaskStats())
        : const TaskStats();

    return Result.success(
      TasksMessagesOverview(
        tasks: tasks,
        conversations: conversations,
        stats: tasks.isNotEmpty ? listStats : apiStats,
        recurringChecks: recurringResult.isSuccess
            ? (recurringResult.value ?? const [])
            : const [],
      ),
    );
  }

  @override
  Future<Result<List<StaffTask>>> getMyTasks() async {
    final result = await _api.get(
      ApiEndpoints.tasks,
      query: {'page': 1, 'limit': 50, 'residenceId': ?_session.residenceId},
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffTasksMessagesMapper.tasksFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<TaskStats>> getTaskStats() async {
    final result = await _api.get(
      ApiEndpoints.tasksStats,
      query: {'residenceId': ?_session.residenceId},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffTasksMessagesMapper.statsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffTaskDetail>> getTaskDetail(String taskId) async {
    final results = await Future.wait([
      _api.get(ApiEndpoints.taskById(taskId)),
      _api.get(ApiEndpoints.taskNotes(taskId), silent: true),
    ]);
    if (results[0].isFailure) {
      return Result.failure(
        results[0].error ??
            const ApiError(message: 'Could not load this task.'),
      );
    }
    return Result.success(
      StaffTasksMessagesMapper.taskDetailFrom(
        detailBody: results[0].value,
        notesBody: results[1].isSuccess ? results[1].value : const [],
      ),
    );
  }

  @override
  Future<Result<void>> completeTask(String taskId) async {
    final result = await _api.patch(
      ApiEndpoints.taskById(taskId),
      data: const {'status': 'completed'},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<TaskCreationOptions>> getTaskCreationOptions() async {
    final now = DateTime.now();
    final start = IsoDateRange.startOfLocalDay(
      now,
    ).subtract(const Duration(days: 1)).toUtc().toIso8601String();
    final end = IsoDateRange.startOfLocalDay(
      now,
    ).add(const Duration(days: 31)).toUtc().toIso8601String();
    final residenceId = _session.residenceId?.trim();

    final results = await Future.wait([
      _api.get(
        ApiEndpoints.shifts,
        query: {'mine': true, 'from': start, 'to': end, 'page': 1, 'limit': 50},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.residences,
        query: const {'page': 1, 'limit': 100},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.staff,
        query: {
          if (residenceId != null && residenceId.isNotEmpty)
            'residenceId': residenceId,
          'page': 1,
          'limit': 100,
        },
        silent: true,
      ),
    ]);

    final shiftsResult = results[0];
    if (shiftsResult.isFailure) {
      return Result.failure(
        shiftsResult.error ??
            const ApiError(message: 'Could not load your shifts.'),
      );
    }

    final defaultStaffId = await _resolveCurrentStaffId();
    final residences = _taskOptionsFrom(
      results[1].isSuccess ? results[1].value : const [],
      titleKeys: const ['name', 'title'],
    );
    final sessionResidenceName = _session.residenceName?.trim();
    if (residenceId != null &&
        residenceId.isNotEmpty &&
        !residences.any((option) => option.id == residenceId)) {
      residences.insert(
        0,
        TaskCreationOption(
          id: residenceId,
          label: sessionResidenceName?.isNotEmpty == true
              ? sessionResidenceName!
              : 'Current residence',
        ),
      );
    }

    return Result.success(
      TaskCreationOptions(
        shifts: _shiftOptionsFrom(shiftsResult.value),
        residences: residences,
        staff: _staffOptionsFrom(results[2].isSuccess ? results[2].value : []),
        defaultResidenceId: residenceId,
        defaultStaffId: defaultStaffId,
      ),
    );
  }

  @override
  Future<Result<List<TaskCreationOption>>> getTaskRooms(
    String residenceId,
  ) async {
    final id = residenceId.trim();
    if (id.isEmpty) return Result.success(const []);
    final result = await _api.get(
      ApiEndpoints.residenceRooms(id),
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final name = JsonCodec.stringOr(json['name'] ?? json['number'], 'Room');
          final floor = JsonCodec.stringOr(json['floor'], '');
          final wing = JsonCodec.stringOr(json['wing'], '');
          final subtitle = [
            if (floor.isNotEmpty) floor,
            if (wing.isNotEmpty) wing,
          ].join(' · ');
          return TaskCreationOption(
            id: name,
            label: name.startsWith('Room') ? name : 'Room $name',
            subtitle: subtitle,
          );
        }).toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<TaskCreationOption>>> getTaskClients(
    String residenceId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        if (residenceId.trim().isNotEmpty) 'residenceId': residenceId.trim(),
        'page': 1,
        'limit': 100,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final name = IsoDateRange.personName(json);
          return TaskCreationOption(
            id: JsonCodec.stringOr(json['id'], ''),
            label: name == 'Unknown'
                ? JsonCodec.stringOr(json['name'], 'Resident')
                : name,
            subtitle: JsonCodec.stringOr(json['roomNumber'], ''),
          );
        }).where((option) => option.id.isNotEmpty).toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<TaskCreationOption>>> getTaskShifts(
    String residenceId,
  ) async {
    final now = DateTime.now();
    final from = IsoDateRange.startOfLocalDay(
      now,
    ).subtract(const Duration(days: 1)).toUtc().toIso8601String();
    final to = IsoDateRange.startOfLocalDay(
      now,
    ).add(const Duration(days: 31)).toUtc().toIso8601String();
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        if (residenceId.trim().isNotEmpty) 'residenceId': residenceId.trim(),
        'from': from,
        'to': to,
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(_shiftOptionsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
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
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Task title is required.'),
      );
    }
    final normalizedResidenceId = residenceId.trim();
    if (normalizedResidenceId.isEmpty) {
      return Result.failure(
        const ValidationError(
          message: 'Residence is required to create a task.',
        ),
      );
    }
    final staffIds = assignedStaffIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (staffIds.isEmpty) {
      final resolved = await _resolveCurrentStaffId();
      if (resolved != null && resolved.isNotEmpty) staffIds.add(resolved);
    }
    if (staffIds.isEmpty) {
      return Result.failure(
        const ValidationError(
          message: 'A staff assignee is required to create a task.',
        ),
      );
    }

    final checklistPayload = checklist
        .map((item) {
          final label = (item['label'] ?? item['text'] ?? '').toString().trim();
          if (label.isEmpty) return null;
          return {
            'label': label,
            'required': item['required'] == true,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (isRecurring) {
      final frequency = recurrenceFrequency.trim().isEmpty
          ? 'daily'
          : recurrenceFrequency.trim();
      final result = await _api.post(
        ApiEndpoints.tasksRecurring,
        data: {
          'title': trimmed,
          'residenceId': normalizedResidenceId,
          'priority': priority.toLowerCase(),
          'taskType': _normalizeTaskType(taskType),
          'assignedStaffIds': staffIds,
          'requiresReview': requiresReview,
          'frequency': frequency,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (clientId != null && clientId.trim().isNotEmpty)
            'clientId': clientId.trim(),
          if (checklistPayload.isNotEmpty) 'checklist': checklistPayload,
          if (frequency == 'interval')
            'intervalMinutes': recurrenceIntervalMinutes ?? 1440,
          if (frequency != 'interval')
            'timesOfDay': recurrenceTimesOfDay.isNotEmpty
                ? recurrenceTimesOfDay
                : [9 * 60],
        },
        silent: true,
        allowQueue: false,
      );
      return result.when(
        success: (_) async => Result.success(null),
        failure: (error) async => Result.failure(error),
      );
    }

    final normalizedShiftId = shiftId?.trim() ?? '';
    if (normalizedShiftId.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Shift is required to create a task.'),
      );
    }

    final result = await _api.post(
      ApiEndpoints.tasks,
      data: {
        'title': trimmed,
        'residenceId': normalizedResidenceId,
        'priority': priority.toLowerCase(),
        'taskType': _normalizeTaskType(taskType),
        'shiftId': normalizedShiftId,
        'assignedStaffIds': staffIds,
        'requiresReview': requiresReview,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
        if (clientId != null && clientId.trim().isNotEmpty)
          'clientId': clientId.trim(),
        if (roomArea != null && roomArea.trim().isNotEmpty)
          'roomArea': roomArea.trim(),
        if (checklistPayload.isNotEmpty) 'checklist': checklistPayload,
      },
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final note = notes?.trim() ?? '';
        if (note.isEmpty) return Result.success(null);
        final taskId = JsonCodec.string(
          JsonCodec.mapAt(body, 'data')?['id'] ?? body?['id'],
        );
        if (taskId == null || taskId.isEmpty) return Result.success(null);
        await addTaskNote(taskId: taskId, body: note);
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> addTaskNote({
    required String taskId,
    required String body,
  }) async {
    final result = await _api.post(
      ApiEndpoints.taskNotes(taskId),
      data: {'body': body, 'note': body, 'text': body},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<RecurringCheckInstance>>> getMyRecurringChecks() async {
    final now = DateTime.now();
    return getRecurringCheckInstances(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 1),
      status: 'pending',
      mine: true,
    );
  }

  @override
  Future<Result<List<RecurringCheckSchedule>>>
  getRecurringCheckSchedules() async {
    final result = await _api.get(
      ApiEndpoints.recurringCheckSchedules,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffTasksMessagesMapper.recurringSchedulesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckInstances({
    DateTime? from,
    DateTime? to,
    String? status,
    String? residenceId,
    bool mine = false,
  }) async {
    var result = await _api.get(
      ApiEndpoints.recurringCheckInstances,
      query: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        if (residenceId != null &&
            residenceId.isNotEmpty &&
            residenceId != 'all')
          'residenceId': residenceId,
        if (mine) 'mine': true,
        'page': 1,
        'limit': 100,
      },
      silent: true,
    );
    if (result.isSuccess &&
        StaffTasksMessagesMapper.recurringFrom(result.value).isEmpty &&
        from != null &&
        to != null) {
      result = await _api.get(
        ApiEndpoints.recurringCheckInstances,
        query: {
          if (status != null && status.isNotEmpty && status != 'all')
            'status': status,
          if (residenceId != null &&
              residenceId.isNotEmpty &&
              residenceId != 'all')
            'residenceId': residenceId,
          if (mine) 'mine': true,
          'page': 1,
          'limit': 100,
        },
        silent: true,
      );
    }
    return result.when(
      success: (body) async =>
          Result.success(StaffTasksMessagesMapper.recurringFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateRecurringCheck({
    required String instanceId,
    required String status,
    String? statusNote,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.recurringCheckInstanceById(instanceId),
      data: {
        'status': status,
        if (statusNote != null && statusNote.trim().isNotEmpty)
          'statusNote': statusNote.trim(),
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createRecurringCheckSchedule({
    required String residenceId,
    required String clientId,
    required String name,
    String checkType = 'other',
    String? instructions,
    String frequency = 'interval',
    int intervalMinutes = 30,
    String? activeFromMinute,
    String? activeToMinute,
    DateTime? effectiveFrom,
    DateTime? expiresAt,
    bool alertEnabled = false,
    String? assignedRole,
    String? assignedStaffId,
  }) async {
    final fromMinute = _minuteOfDay(activeFromMinute);
    final toMinute = _minuteOfDay(activeToMinute);
    final role = assignedRole?.trim() ?? '';
    final staffId = assignedStaffId?.trim() ?? '';
    final result = await _api.post(
      ApiEndpoints.recurringCheckSchedules,
      data: {
        'clientId': clientId,
        'residenceId': residenceId,
        'name': name.trim(),
        'checkType': checkType.trim().isEmpty ? 'other' : checkType.trim(),
        if (instructions != null && instructions.trim().isNotEmpty)
          'instructions': instructions.trim(),
        'frequency': frequency,
        'intervalMinutes': intervalMinutes,
        if (fromMinute != null) 'activeFromMinute': fromMinute,
        if (toMinute != null) 'activeToMinute': toMinute,
        if (effectiveFrom != null)
          'effectiveFrom': effectiveFrom.toUtc().toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
        'alertEnabled': alertEnabled,
        if (alertEnabled)
          'alertRules': {
            'rules': [
              {
                'field': 'outcome',
                'operator': 'ne',
                'value': 'normal',
              },
            ],
            'notifyRoles': [role.isEmpty ? 'nurse' : role],
          },
        if (role.isNotEmpty) 'assignedRole': role,
        if (staffId.isNotEmpty) 'assignedStaffId': staffId,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateRecurringCheckSchedule({
    required String scheduleId,
    required Map<String, dynamic> fields,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.recurringCheckScheduleById(scheduleId),
      data: fields,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> deleteRecurringCheckSchedule(String scheduleId) async {
    final result = await _api.delete(
      ApiEndpoints.recurringCheckScheduleById(scheduleId),
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordRecurringCheckProgress({
    required String clientId,
    required String residenceId,
    required String note,
    String checkName = 'Welfare observation',
    String outcome = 'normal',
    String? scheduleId,
  }) async {
    final result = await _api.post(
      ApiEndpoints.recurringCheckEntries,
      data: {
        'clientId': clientId,
        'residenceId': residenceId,
        'checkName': checkName.trim().isEmpty
            ? 'Welfare observation'
            : checkName.trim(),
        'note': note.trim(),
        'outcome': outcome,
        if (scheduleId != null && scheduleId.trim().isNotEmpty)
          'scheduleId': scheduleId.trim(),
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<RecurringCheckInstance>>> getRecurringCheckEntries({
    String? residenceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get(
      ApiEndpoints.recurringCheckEntries,
      query: {
        if (residenceId != null &&
            residenceId.isNotEmpty &&
            residenceId != 'all')
          'residenceId': residenceId,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        'page': 1,
        'limit': 100,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.recurringEntriesFrom(body),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getTrainingAssignments() async {
    final staffId = _session.staffId?.trim();
    final result = await _api.get(
      ApiEndpoints.trainingAssignments,
      query: {
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.simpleRowsFrom(body, titleKey: 'courseName'),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getDocuments() async {
    final result = await _api.get(
      ApiEndpoints.documents,
      query: const {'page': 1, 'limit': 20},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.simpleRowsFrom(body, titleKey: 'name'),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async {
    final result = await _api.get(ApiEndpoints.conversations);
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (item) => StaffTasksMessagesMapper.conversationFrom(
                JsonCodec.asMap(item),
                currentUserId: _session.userId,
              ),
            )
            .toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<MessageContact>>> getContacts() async {
    final result = await _api.get(
      ApiEndpoints.conversationContacts,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffTasksMessagesMapper.contactsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<ConversationPreview>> startConversation({
    required String title,
    required List<String> memberUserIds,
  }) async {
    final trimmedTitle = title.trim();
    final members = memberUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (members.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Select at least one contact.'),
      );
    }
    final residenceId = _session.residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      return Result.failure(
        const ValidationError(
          message: 'Residence context is required to start a conversation.',
        ),
      );
    }

    final result = await _api.post(
      ApiEndpoints.conversations,
      data: {
        'type': 'residence_group',
        'residenceId': residenceId,
        // API still expects a title; blank UI title becomes selected names / fallback.
        'title': trimmedTitle.isEmpty ? 'Conversation' : trimmedTitle,
        'memberUserIds': members,
        'isMonitored': false,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.conversationFrom(
          JsonCodec.unwrapMap(body),
          currentUserId: _session.userId,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MessageThread>> getThread({
    required String conversationId,
    String? contactName,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }
    final result = await _api.get(ApiEndpoints.conversationMessages(id));
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.threadFrom(
          conversationId: id,
          contactName: (contactName ?? '').trim().isEmpty
              ? 'Conversation'
              : contactName!.trim(),
          messagesBody: body,
          currentUserId: _session.userId,
          currentUserEmail: _session.email,
          selfInitials: _session.avatarInitials,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> sendMessage({
    required String conversationId,
    required String body,
    String priority = 'general',
  }) async {
    final id = conversationId.trim();
    final text = body.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }
    if (text.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Message body is required.'),
      );
    }
    final normalized = switch (priority.toLowerCase().trim()) {
      'high' || 'high_priority' || 'highpriority' => 'high',
      'routine' => 'routine',
      _ => 'general',
    };
    final result = await _api.post(
      ApiEndpoints.conversationMessages(id),
      data: {'body': text, 'priority': normalized},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.conversationRead(id),
      data: const <String, dynamic>{},
      allowQueue: false,
      silent: true,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markAllConversationsRead() async {
    final result = await _api.post(
      ApiEndpoints.conversationsReadAll,
      data: const <String, dynamic>{},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<String?> _resolveCurrentStaffId() async {
    final sessionStaffId = _session.staffId?.trim();
    if (sessionStaffId != null && sessionStaffId.isNotEmpty) {
      return sessionStaffId;
    }
    final email = _session.email.trim();
    if (email.isEmpty) return null;

    final result = await _api.get(
      ApiEndpoints.staff,
      query: {'email': email, 'page': 1, 'limit': 10},
      silent: true,
    );
    if (result.isFailure) return null;

    final lowerEmail = email.toLowerCase();
    for (final item in JsonCodec.unwrapList(result.value).whereType<Map>()) {
      final json = JsonCodec.asMap(item);
      final rowEmail = JsonCodec.stringOr(json['email'], '').toLowerCase();
      if (rowEmail == lowerEmail) {
        final id = JsonCodec.string(json['id']);
        if (id != null) {
          _session.applyStaffContext(staffId: id);
          return id;
        }
      }
    }
    for (final item in JsonCodec.unwrapList(result.value).whereType<Map>()) {
      final id = JsonCodec.string(JsonCodec.asMap(item)['id']);
      if (id != null) {
        _session.applyStaffContext(staffId: id);
        return id;
      }
    }
    return null;
  }

  static String _normalizeTaskType(String value) {
    final raw = value.trim().toLowerCase();
    return switch (raw) {
      'administrative' ||
      'maintenance' ||
      'inventory' ||
      'compliance' ||
      'follow_up' ||
      'other' => raw,
      'follow up' || 'follow-up' => 'follow_up',
      _ => 'other',
    };
  }

  static List<TaskCreationOption> _shiftOptionsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final start = JsonCodec.dateTime(
            json['startAt'] ??
                json['startsAt'] ??
                json['startTime'] ??
                json['from'],
          );
          final end = JsonCodec.dateTime(
            json['endAt'] ?? json['endsAt'] ?? json['endTime'] ?? json['to'],
          );
          final title = JsonCodec.stringOr(
            json['title'] ??
                json['name'] ??
                json['shiftType'] ??
                json['period'],
            'Shift',
          );
          final time = IsoDateRange.rangeLabel(start, end);
          final date = start == null
              ? ''
              : IsoDateRange.formatShortDate(start.toLocal());
          return TaskCreationOption(
            id: JsonCodec.stringOr(json['id'], title),
            label: title,
            subtitle: [
              if (date.isNotEmpty) date,
              if (time.isNotEmpty) time,
            ].join(' · '),
          );
        })
        .where((option) => option.id.isNotEmpty)
        .toList();
  }

  static List<TaskCreationOption> _staffOptionsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          final name = IsoDateRange.personName(json);
          return TaskCreationOption(
            id: JsonCodec.stringOr(json['id'], ''),
            label: name == 'Unknown'
                ? JsonCodec.stringOr(json['email'], 'Staff')
                : name,
            subtitle: JsonCodec.stringOr(
              JsonCodec.mapAt(json, 'category')?['name'] ??
                  json['employmentType'] ??
                  json['email'],
              '',
            ),
          );
        })
        .where((option) => option.id.isNotEmpty)
        .toList();
  }

  static List<TaskCreationOption> _taskOptionsFrom(
    dynamic body, {
    required List<String> titleKeys,
  }) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) {
          final json = JsonCodec.asMap(item);
          String? title;
          for (final key in titleKeys) {
            title ??= JsonCodec.string(json[key]);
          }
          return TaskCreationOption(
            id: JsonCodec.stringOr(json['id'], title ?? ''),
            label: title ?? 'Option',
          );
        })
        .where((option) => option.id.isNotEmpty)
        .toList();
  }

  /// Accepts `HH:mm`, `H:mm`, or a raw minute-of-day integer string.
  static int? _minuteOfDay(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return (hours * 60) + minutes;
  }
}
