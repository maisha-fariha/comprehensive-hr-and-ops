import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/conversation_preview.dart';
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

  const FamilyMessagesMapper._();
}
