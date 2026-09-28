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
  Future<Result<void>> createTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueAt,
    required String taskType,
    required String shiftId,
    required String residenceId,
    List<String> assignedStaffIds = const [],
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
    final normalizedShiftId = shiftId.trim();
    if (normalizedShiftId.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Shift is required to create a task.'),
      );
    }
    final staffIds = assignedStaffIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (staffIds.isEmpty) {
      final staffId = await _resolveCurrentStaffId();
      if (staffId != null && staffId.isNotEmpty) staffIds.add(staffId);
    }
    if (staffIds.isEmpty) {
      return Result.failure(
        const ValidationError(
          message: 'A staff assignee is required to create a task.',
        ),
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
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
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
    final from = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
    final to = DateTime(now.year, now.month + 1, 1).toUtc().toIso8601String();
    var result = await _api.get(
      ApiEndpoints.recurringCheckInstances,
      query: {
        'status': 'pending',
        'from': from,
        'to': to,
        'page': 1,
        'limit': 100,
      },
      silent: true,
    );
    if (result.isSuccess &&
        StaffTasksMessagesMapper.recurringFrom(result.value).isEmpty) {
      result = await _api.get(
        ApiEndpoints.recurringCheckInstances,
        query: const {'status': 'pending', 'page': 1, 'limit': 100},
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
}
