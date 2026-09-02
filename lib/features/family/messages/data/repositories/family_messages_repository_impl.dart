import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/repositories/family_messages_repository.dart';
import '../mappers/family_messages_mapper.dart';

class FamilyMessagesRepositoryImpl implements FamilyMessagesRepository {
  final AppApiClient _api;

  FamilyMessagesRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<List<ConversationPreview>>> getConversations() async {
    final result = await _api.get(
      ApiEndpoints.familyMessages,
      query: const {'page': 1, 'limit': 20},
    );
    return result.when(
      success: (body) async =>
          Result.success(FamilyMessagesMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyConversationMessages(conversationId),
      data: {
        'body': body,
        if (highPriority) 'priority': 'high',
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> startConversation({
    required String clientId,
    required String body,
    bool highPriority = false,
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyMessages,
      data: {
        'clientId': clientId,
        'body': body,
        if (highPriority) 'priority': 'high',
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
