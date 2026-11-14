import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../domain/entities/message_attachment.dart';

abstract final class FamilyMessagesMapper {
  static List<ConversationPreview> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .where((json) => JsonCodec.boolean(json['hidden']) != true)
        .map(fromJson)
        .toList();
  }

  static ConversationPreview fromJson(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ?? {};
    final last = JsonCodec.mapAt(json, 'lastMessage') ?? json;
    final name = JsonCodec.stringOr(
      json['title'] ?? json['name'] ?? IsoDateRange.personName(client),
      'Care team',
    );
    final at = JsonCodec.dateTime(
      last['createdAt'] ?? last['sentAt'] ?? json['updatedAt'],
    );
    return ConversationPreview(
      id: JsonCodec.stringOr(json['id'], name),
      name: name,
      subtitle: JsonCodec.stringOr(
        json['subtitle'] ?? client['name'] ?? json['type'],
        'Care team',
      ),
      avatarType: ConversationAvatarType.team,
      initials: IsoDateRange.initials(name),
      accent: ConversationAccent.blue,
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at),
      previewText: JsonCodec.stringOr(
        last['body'] ?? last['text'] ?? last['preview'],
        '',
      ),
      unreadCount: JsonCodec.integerOr(json['unreadCount'], 0),
      left: JsonCodec.boolean(json['left']) ?? false,
    );
  }

  /// `GET /family/messages/:id` returns `{data: [message...]}` where each
  /// message only carries `sender: {id, name}` / `senderId`, so outgoing vs
  /// incoming is decided by comparing with [currentUserId] (web:
  /// `message.sender?.id === me.id`).
  static FamilyConversationThread threadFrom(
    dynamic body, {
    String? currentUserId,
  }) {
    final json = JsonCodec.unwrapMap(body);
    final conversation = JsonCodec.mapAt(json, 'conversation') ?? json;
    final messagesRaw = json['messages'] ?? conversation['messages'] ?? body;
    final title = JsonCodec.stringOr(
      conversation['title'] ?? conversation['name'],
      'Care team',
    );
    return FamilyConversationThread(
      id: JsonCodec.stringOr(conversation['id'] ?? json['id'], 'conversation'),
      title: title,
      messages: JsonCodec.unwrapList(messagesRaw)
          .whereType<Map>()
          .map(
            (item) => messageFrom(
              JsonCodec.asMap(item),
              currentUserId: currentUserId,
            ),
          )
          .toList(),
    );
  }

  static FamilyChatMessage messageFrom(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final sender = JsonCodec.mapAt(json, 'sender') ?? {};
    final senderName = IsoDateRange.personName(
      sender.isEmpty ? json['senderName'] : sender,
    );
    final role = (JsonCodec.string(
              sender['role'] ?? json['senderRole'] ?? json['senderType'],
            ) ??
            '')
        .toLowerCase();
    final senderId = JsonCodec.string(sender['id'] ?? json['senderId']);
    final mine = JsonCodec.boolean(json['isMine'] ?? json['fromFamily']) ??
        ((currentUserId != null &&
                currentUserId.isNotEmpty &&
                senderId == currentUserId) ||
            role.contains('family'));
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
    return FamilyChatMessage(
      id: JsonCodec.stringOr(json['id'], 'message'),
      text: JsonCodec.stringOr(json['body'] ?? json['text'], ''),
      direction:
          mine ? FamilyMessageDirection.outgoing : FamilyMessageDirection.incoming,
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at),
      senderName:
          mine ? 'You' : (senderName == 'Unknown' ? 'Care team' : senderName),
      attachments: _attachmentsFrom(json['attachments']),
    );
  }

  static List<MessageAttachment> _attachmentsFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <MessageAttachment>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final url = JsonCodec.string(
        json['fileUrl'] ?? json['url'] ?? json['publicUrl'],
      );
      if (url == null || url.isEmpty) continue;
      final name = JsonCodec.stringOr(
        json['fileName'] ?? json['name'],
        _fileNameFromUrl(url),
      );
      out.add(
        MessageAttachment(
          fileUrl: url,
          fileType: JsonCodec.stringOr(
            json['fileType'] ?? json['mimeType'] ?? json['contentType'],
            'application/octet-stream',
          ),
          fileName: name,
        ),
      );
    }
    return out;
  }

  static String _fileNameFromUrl(String url) {
    final path = url.split('?').first;
    final slash = path.lastIndexOf('/');
    if (slash < 0 || slash == path.length - 1) return 'Attachment';
    return path.substring(slash + 1);
  }

  const FamilyMessagesMapper._();
}
