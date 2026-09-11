import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_conversation.dart';
import '../../domain/entities/hr_message_contact.dart';
import '../../domain/repositories/communication_repository.dart';
import '../mappers/communication_mapper.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final AppApiClient _api;
  final UserSession _session;

  CommunicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<List<HrConversation>>> getConversations() async {
    final result = await _api.get(ApiEndpoints.conversations);
    return result.when(
      success: (body) async =>
          Result.success(CommunicationMapper.conversationsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<HrMessageContact>>> getContacts() async {
    final result = await _api.get(
      ApiEndpoints.conversationContacts,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(CommunicationMapper.contactsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<HrChatMessage>>> getMessages(String conversationId) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }

    final result = await _api.get(ApiEndpoints.conversationMessages(id));
    return result.when(
      success: (body) async => Result.success(
        CommunicationMapper.messagesFrom(
          body,
          currentUserId: _session.userId,
          currentUserEmail: _session.email,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<HrConversation>> startConversation({
    required String title,
    required List<String> memberUserIds,
    String? clientId,
    bool isMonitored = false,
  }) async {
    final trimmedTitle = title.trim();
    final members = memberUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (trimmedTitle.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Conversation title is required.'),
      );
    }
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

    // Postman Manager sample only documents `type: residence_group`.
    final result = await _api.post(
      ApiEndpoints.conversations,
      data: {
        'type': 'residence_group',
        'residenceId': residenceId,
        'title': trimmedTitle,
        'memberUserIds': members,
        'isMonitored': isMonitored,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      },
      allowQueue: false,
    );

    return result.when(
      success: (body) async => Result.success(
        CommunicationMapper.conversationFrom(JsonCodec.unwrapMap(body)),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<HrChatMessage>> sendMessage({
    required String conversationId,
    required String body,
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

    final result = await _api.post(
      ApiEndpoints.conversationMessages(id),
      data: {
        'priority': 'general',
        'body': text,
      },
      allowQueue: false,
    );

    return result.when(
      success: (response) async => Result.success(
        CommunicationMapper.messageFrom(
          JsonCodec.unwrapMap(response),
          currentUserId: _session.userId,
          currentUserEmail: _session.email,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markThreadRead(String conversationId) async {
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
  Future<Result<void>> markAllRead() async {
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

  @override
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> memberUserIds,
  }) async {
    final id = conversationId.trim();
    final members = memberUserIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }
    if (members.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Select at least one contact.'),
      );
    }

    final result = await _api.post(
      ApiEndpoints.conversationMembers(id),
      data: {'memberUserIds': members},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> removeMember({
    required String conversationId,
    required String memberId,
  }) async {
    final id = conversationId.trim();
    final member = memberId.trim();
    if (id.isEmpty || member.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation or member id.'),
      );
    }

    final result = await _api.delete(
      ApiEndpoints.conversationMember(id, member),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<HrConversation>> updateConversation({
    required String conversationId,
    String? title,
    bool? archived,
  }) async {
    final id = conversationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing conversation id.'),
      );
    }

    final data = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      'archived': ?archived,
    };
    if (data.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Nothing to update.'),
      );
    }

    final result = await _api.patch(
      ApiEndpoints.conversationById(id),
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        CommunicationMapper.conversationFrom(JsonCodec.unwrapMap(body)),
      ),
      failure: (error) async => Result.failure(error),
    );
  }
}
