import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/family_notification.dart';

abstract final class FamilyNotificationsMapper {
  static List<FamilyNotification> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => fromJson(JsonCodec.asMap(item)))
        .toList();
  }

  static FamilyNotification fromJson(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
    return FamilyNotification(
      id: JsonCodec.stringOr(json['id'], 'notification'),
      title: JsonCodec.stringOr(
        json['title'] ?? json['subject'] ?? json['type'],
        'Notification',
      ),
      body: JsonCodec.stringOr(json['body'] ?? json['message'] ?? json['text'], ''),
      timeLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
      isRead: JsonCodec.boolean(json['isRead'] ?? json['read']) ?? false,
    );
  }

  const FamilyNotificationsMapper._();
}
