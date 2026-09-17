import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/message_attachment.dart';
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
  Future<Result<FamilyConversationThread>> getConversation(String id) async {
    final result = await _api.get(ApiEndpoints.familyConversation(id));
    return result.when(
      success: (body) async =>
          Result.success(FamilyMessagesMapper.threadFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MessageAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: fileName,
        ),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'messages'},
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          return Result.success(
            MessageAttachment(
              fileUrl: url,
              fileType: JsonCodec.stringOr(
                map['mimeType'] ?? map['fileType'] ?? fileType,
                fileType,
              ),
              fileName: JsonCodec.stringOr(map['fileName'], fileName),
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (_) {
      return Result.failure(
        const ApiError(message: 'Could not upload this attachment.'),
      );
    }
  }

  @override
  Future<Result<void>> sendInConversation({
    required String conversationId,
    required String body,
    bool highPriority = false,
    List<MessageAttachment> attachments = const [],
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyConversationMessages(conversationId),
      data: {
        'body': body,
        if (highPriority) 'priority': 'high',
        if (attachments.isNotEmpty)
          'attachments': [
            for (final item in attachments) item.toJson(),
          ],
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
    List<MessageAttachment> attachments = const [],
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyMessages,
      data: {
        'clientId': clientId,
        'body': body,
        if (highPriority) 'priority': 'high',
        if (attachments.isNotEmpty)
          'attachments': [
            for (final item in attachments) item.toJson(),
          ],
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
