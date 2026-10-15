import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/communication_enums.dart';
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
  Future<Result<List<HrConversation>>> getConversations({
    bool monitor = false,
  }) async {
    final result = await _api.get(
      ApiEndpoints.conversations,
      query: {
        'page': 1,
        'limit': 100,
        if (monitor) 'monitor': true,
      },
    );
    return result.when(
      success: (body) async => Result.success(
        CommunicationMapper.conversationsFrom(
          body,
          currentUserId: _session.userId,
        ),
      ),
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
  Future<Result<List<CommunicationResidenceOption>>> getResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((raw) {
              final json = JsonCodec.asMap(raw);
              return CommunicationResidenceOption(
                id: JsonCodec.stringOr(json['id'], ''),
                name: JsonCodec.stringOr(json['name'], 'Residence'),
              );
            })
            .where((r) => r.id.isNotEmpty)
            .toList();
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<CommunicationClientOption>>> getClients() async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((raw) {
              final json = JsonCodec.asMap(raw);
              final residence = JsonCodec.mapAt(json, 'residence');
              final name = JsonCodec.stringOr(
                json['displayName'] ??
                    json['name'] ??
                    '${JsonCodec.stringOr(json['firstName'], '')} ${JsonCodec.stringOr(json['lastName'], '')}'
                        .trim(),
                'Resident',
              );
              return CommunicationClientOption(
                id: JsonCodec.stringOr(json['id'], ''),
                name: name.trim().isEmpty ? 'Resident' : name.trim(),
                residenceName: residence == null
                    ? null
                    : JsonCodec.string(residence['name']),
              );
            })
            .where((c) => c.id.isNotEmpty)
            .toList();
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<HrConversation>> startConversation({
    required ConversationCreateType type,
    List<String> memberUserIds = const [],
    String? title,
    String? residenceId,
    String? clientId,
  }) async {
    final members = memberUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    final trimmedTitle = title?.trim();

    final data = <String, dynamic>{
      'type': type.apiValue,
      if (members.isNotEmpty) 'memberUserIds': members,
      if (trimmedTitle != null && trimmedTitle.isNotEmpty) 'title': trimmedTitle,
    };

    switch (type) {
      case ConversationCreateType.direct:
        if (members.isEmpty) {
          return Result.failure(
            const ValidationError(message: 'Select a staff member.'),
          );
        }
      case ConversationCreateType.residenceGroup:
        final residence = (residenceId ?? _session.residenceId)?.trim();
        if (residence == null || residence.isEmpty) {
          return Result.failure(
            const ValidationError(message: 'Residence is required.'),
          );
        }
        if (trimmedTitle == null || trimmedTitle.isEmpty) {
          return Result.failure(
            const ValidationError(message: 'Group name is required.'),
          );
        }
        data['residenceId'] = residence;
      case ConversationCreateType.familySupport:
        final client = clientId?.trim();
        if (client == null || client.isEmpty) {
          return Result.failure(
            const ValidationError(message: 'Select a family contact.'),
          );
        }
        data['clientId'] = client;
        if (members.isNotEmpty) {
          data['memberUserIds'] = members;
        }
    }

    final result = await _api.post(
      ApiEndpoints.conversations,
      data: data,
      allowQueue: false,
    );

    return result.when(
      success: (body) async => Result.success(
        CommunicationMapper.conversationFrom(
          JsonCodec.unwrapMap(body),
          currentUserId: _session.userId,
        ),
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

  @override
  Future<Result<AnnouncementFeed>> getAnnouncements({
    String view = 'feed',
  }) async {
    final result = await _api.get(
      ApiEndpoints.announcements,
      query: {'view': view},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final map = JsonCodec.unwrapMap(body);
        final rows = JsonCodec.unwrapList(map.isEmpty ? body : map['items'] ?? body);
        return Result.success(
          AnnouncementFeed(
            items: rows.whereType<Map>().map(_announcement).toList(),
            unreadCount: JsonCodec.integerOr(map['unreadCount'], 0),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> markAnnouncementRead(String id) async {
    final result = await _api.post(
      ApiEndpoints.announcementRead(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<CommunicationLogEntry>>> getCommunicationLogs() async {
    final result = await _api.get(
      ApiEndpoints.communicationLogs,
      query: const {'page': 1, 'limit': 20},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final rows = JsonCodec.unwrapList(body);
        return Result.success(rows.whereType<Map>().map(_log).toList());
      },
      failure: (error) async => Result.failure(error),
    );
  }

  HrAnnouncement _announcement(Map raw) {
    final json = JsonCodec.asMap(raw);
    final author = JsonCodec.mapAt(json, 'author') ?? const {};
    final audience = JsonCodec.mapAt(json, 'audience') ?? const {};
    final type = JsonCodec.string(audience['type']);
    String audienceLabel = 'All staff';
    if (type == 'residences') {
      final ids = JsonCodec.unwrapList(audience['residenceIds']);
      if (ids.isNotEmpty) audienceLabel = ids.map((id) => '$id').join(', ');
    } else if (type == 'roles') {
      final roles = JsonCodec.unwrapList(audience['roles']);
      audienceLabel = roles
          .map((role) => '$role'.replaceAll('_', ' '))
          .where((role) => role.isNotEmpty)
          .join(', ');
      if (audienceLabel.isEmpty) audienceLabel = 'All staff';
    }
    final created = JsonCodec.dateTime(json['createdAt']);
    final createdLabel = created == null
        ? ''
        : _stamp(created.toLocal());
    return HrAnnouncement(
      id: JsonCodec.stringOr(json['id'], ''),
      title: JsonCodec.stringOr(json['title'], 'Announcement'),
      body: JsonCodec.stringOr(json['body'], ''),
      authorName: JsonCodec.stringOr(author['name'], 'Management'),
      audienceLabel: audienceLabel,
      createdLabel: createdLabel,
      important: JsonCodec.string(json['priority']) == 'important',
      read: json['read'] == true,
    );
  }

  CommunicationLogEntry _log(Map raw) {
    final json = JsonCodec.asMap(raw);
    final type = JsonCodec.stringOr(json['type'], '');
    final when = JsonCodec.dateTime(json['occurredAt']);
    return CommunicationLogEntry(
      id: JsonCodec.stringOr(json['id'], type),
      whenLabel: when == null ? '—' : _stamp(when.toLocal()),
      sender: JsonCodec.stringOr(json['sender'], 'System'),
      recipient: JsonCodec.stringOr(json['recipient'], '—'),
      typeLabel: switch (type) {
        'handover' => 'Shift handover',
        'daily_update' => 'Daily update',
        '' => '—',
        _ => type
            .replaceAll('_', ' ')
            .replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase()),
      },
      preview: JsonCodec.stringOr(json['contentPreview'], ''),
      conversationId: JsonCodec.string(json['conversationId']),
    );
  }

  String _stamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}
