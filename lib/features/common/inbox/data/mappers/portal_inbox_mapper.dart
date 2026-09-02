import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/portal_notification.dart';
import '../../domain/entities/portal_search_hit.dart';

abstract final class PortalInboxMapper {
  static List<PortalSearchHit> searchFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => searchHitFrom(JsonCodec.asMap(item)))
        .toList();
  }

  static PortalSearchHit searchHitFrom(Map<String, dynamic> json) {
    final type = _type(json['type'] ?? json['kind'] ?? json['entityType']);
    final at = JsonCodec.dateTime(json['occurredAt'] ?? json['createdAt']);
    return PortalSearchHit(
      id: JsonCodec.stringOr(json['id'] ?? json['entityId'], 'hit'),
      type: type,
      title: JsonCodec.stringOr(
        json['title'] ?? json['name'] ?? json['subject'],
        _label(type),
      ),
      subtitle: [
        JsonCodec.string(json['snippet'] ?? json['body'] ?? json['preview']),
        if (at != null) IsoDateRange.dateTimeLabel(at),
      ].whereType<String>().join(' · '),
    );
  }

  static List<PortalNotification> notificationsFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => notificationFrom(JsonCodec.asMap(item)))
        .toList();
  }

  static PortalNotification notificationFrom(Map<String, dynamic> json) {
    final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
    return PortalNotification(
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

  static PortalSearchHitType _type(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'client':
      case 'resident':
        return PortalSearchHitType.client;
      case 'staff':
      case 'user':
      case 'employee':
        return PortalSearchHitType.staff;
      case 'shift':
        return PortalSearchHitType.shift;
      case 'incident':
        return PortalSearchHitType.incident;
      case 'task':
        return PortalSearchHitType.task;
      case 'document':
        return PortalSearchHitType.document;
      case 'message':
      case 'conversation':
        return PortalSearchHitType.message;
      case 'medication':
      case 'mar':
        return PortalSearchHitType.medication;
      case 'attendance':
        return PortalSearchHitType.attendance;
      default:
        return PortalSearchHitType.unknown;
    }
  }

  static String _label(PortalSearchHitType type) {
    switch (type) {
      case PortalSearchHitType.client:
        return 'Client';
      case PortalSearchHitType.staff:
        return 'Staff';
      case PortalSearchHitType.shift:
        return 'Shift';
      case PortalSearchHitType.incident:
        return 'Incident';
      case PortalSearchHitType.task:
        return 'Task';
      case PortalSearchHitType.document:
        return 'Document';
      case PortalSearchHitType.message:
        return 'Message';
      case PortalSearchHitType.medication:
        return 'Medication';
      case PortalSearchHitType.attendance:
        return 'Attendance';
      case PortalSearchHitType.unknown:
        return 'Result';
    }
  }

  const PortalInboxMapper._();
}
