import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/message_thread.dart';
import '../../domain/entities/tasks_messages_overview.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';
import '../mappers/staff_tasks_messages_mapper.dart';

class StaffTasksMessagesRepositoryImpl implements StaffTasksMessagesRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffTasksMessagesRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<TasksMessagesOverview>> getOverview() async {
    final results = await Future.wait([
      _api.get(
        ApiEndpoints.tasks,
        query: {
          'assignee': 'me',
          'page': 1,
          'limit': 20,
          'residenceId': ?_session.residenceId,
        },
      ),
      _api.get(ApiEndpoints.conversations),
    ]);
    if (results[0].isFailure) {
      return Result.failure(
        results[0].error ?? const ApiError(message: 'Could not load tasks.'),
      );
    }
    return Result.success(
      StaffTasksMessagesMapper.overview(
        tasksBody: results[0].value,
        conversationsBody: results[1].value,
      ),
    );
  }

  @override
  Future<Result<MessageThread>> getThread(String conversationId) async {
    final result = await _api.get(
      ApiEndpoints.conversationMessages(conversationId),
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTasksMessagesMapper.threadFrom(
          conversationId: conversationId,
          contactName: 'Conversation',
          messagesBody: body,
          selfId: _session.staffId ?? '',
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
    final result = await _api.post(
      ApiEndpoints.conversationMessages(conversationId),
      data: {'body': body, 'priority': priority},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markConversationRead(String conversationId) async {
    final result = await _api.post(
      ApiEndpoints.conversationRead(conversationId),
      data: {},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
