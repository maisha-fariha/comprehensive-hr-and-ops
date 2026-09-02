import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_conversation_thread.dart';
import '../../domain/entities/family_messages_enums.dart';

abstract final class FamilyMessagesMapper {
  static List<ConversationPreview> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => fromJson(JsonCodec.asMap(item)))
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
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      previewText: JsonCodec.stringOr(
        last['body'] ?? last['text'] ?? last['preview'],
        '',
      ),
      unreadCount: JsonCodec.integerOr(json['unreadCount'], 0),
    );
  }

  static FamilyConversationThread threadFrom(dynamic body) {
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
          .map((item) => messageFrom(JsonCodec.asMap(item)))
          .toList(),
    );
  }

  static FamilyChatMessage messageFrom(Map<String, dynamic> json) {
    final sender = JsonCodec.mapAt(json, 'sender') ?? {};
    final senderName = IsoDateRange.personName(
      sender.isEmpty ? json['senderName'] : sender,
    );
    final role = (JsonCodec.string(
              sender['role'] ?? json['senderRole'] ?? json['senderType'],
            ) ??
            '')
        .toLowerCase();
    final mine = JsonCodec.boolean(json['isMine'] ?? json['fromFamily']) ??
        role.contains('family');
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
    return FamilyChatMessage(
      id: JsonCodec.stringOr(json['id'], 'message'),
      text: JsonCodec.stringOr(json['body'] ?? json['text'], ''),
      direction:
          mine ? FamilyMessageDirection.outgoing : FamilyMessageDirection.incoming,
      timeLabel: at == null ? '' : IsoDateRange.timeLabel(at.toLocal()),
      senderName:
          mine ? 'You' : (senderName == 'Unknown' ? 'Care team' : senderName),
    );
  }

  const FamilyMessagesMapper._();
}
