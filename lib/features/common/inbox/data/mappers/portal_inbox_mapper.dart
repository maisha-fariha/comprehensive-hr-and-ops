import 'dart:convert';

import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/time/tenant_clock.dart';
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
    final at = JsonCodec.dateTime(
      json['createdAt'] ?? json['sentAt'] ?? json['updatedAt'],
    );
    final metaRaw = json['metaJson'] ?? json['meta'];
    final meta = Map<String, dynamic>.from(_metaMap(metaRaw));
    // Web bell: `severity || metaJson.severity` — keep top-level on meta.
    final topSeverity = JsonCodec.string(json['severity']);
    if (topSeverity != null &&
        topSeverity.isNotEmpty &&
        meta['severity'] == null) {
      meta['severity'] = topSeverity;
    }
    final rawBody = JsonCodec.stringOr(
      json['body'] ?? json['message'] ?? json['text'],
      '',
    );
    final eventKey = JsonCodec.string(json['eventKey'] ?? meta['eventKey']);
    return PortalNotification(
      id: JsonCodec.stringOr(
        json['id'] ?? json['notificationId'],
        'notification',
      ),
      title: JsonCodec.stringOr(
        json['title'] ?? json['subject'] ?? json['type'],
        'Notification',
      ),
      // Web rebuilds shift time bodies with Settings → General timeFormat.
      body: _shiftWhenBody(meta, eventKey) ?? rawBody,
      timeLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
      isRead: isNotificationRead(json),
      createdAt: at,
      entityType: JsonCodec.string(json['entityType']),
      entityId: JsonCodec.string(json['entityId']),
      eventKey: eventKey,
      eventLabel: JsonCodec.string(json['eventLabel']),
      meta: meta,
    );
  }

  /// Web bell: `Wed 04/11/2026, 01:00 pm—03:00 pm` (12h/24h from tenant settings).
  static String? _shiftWhenBody(Map<String, dynamic> meta, String? eventKey) {
    final start = JsonCodec.dateTime(
      meta['shiftStartsAt'] ?? meta['startsAt'] ?? meta['startAt'],
    );
    final end = JsonCodec.dateTime(
      meta['shiftEndsAt'] ?? meta['endsAt'] ?? meta['endAt'],
    );
    if (start == null) return null;
    final key = (eventKey ?? '').toLowerCase();
    final isShiftEvent = meta['shiftWhenBody'] == true ||
        key.startsWith('scheduling.shift') ||
        key.contains('shift_reminder') ||
        key.contains('shift.reminder') ||
        key.contains('reminder');
    if (!isShiftEvent) return null;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wall = TenantClock.wallOf(start);
    final day = weekdays[wall.weekday - 1];
    final date = TenantClock.formatDate(start);
    final startLabel = _paddedTenantTime(start);
    final when = end == null
        ? '$day $date, $startLabel'
        : '$day $date, $startLabel—${_paddedTenantTime(end)}';
    if (key.contains('changed') || key.contains('updated')) {
      return 'Now $when';
    }
    return when;
  }

  /// Web bell pads the hour (`01:00 pm` / `13:00`) using Settings → General.
  static String _paddedTenantTime(DateTime instant) {
    final wall = TenantClock.wallOf(instant);
    final minute = wall.minute.toString().padLeft(2, '0');
    if (TenantClock.is24Hour) {
      return '${wall.hour.toString().padLeft(2, '0')}:$minute';
    }
    final h = wall.hour % 12 == 0 ? 12 : wall.hour % 12;
    final ampm = wall.hour >= 12 ? 'pm' : 'am';
    return '${h.toString().padLeft(2, '0')}:$minute $ampm';
  }

  /// Shared read-state parser used by list + dashboard badge counts.
  static bool isNotificationRead(Map<String, dynamic> json) {
    final explicit = JsonCodec.boolean(
      json['isRead'] ?? json['read'] ?? json['seen'],
    );
    if (explicit != null) return explicit;

    final unread = JsonCodec.boolean(json['unread'] ?? json['isUnread']);
    if (unread != null) return !unread;

    final status = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    if (status == 'read' || status == 'seen') return true;
    if (status == 'unread' || status == 'new') return false;

    // Presence of a read timestamp means it was opened.
    if (JsonCodec.dateTime(json['readAt'] ?? json['seenAt']) != null) {
      return true;
    }
    return false;
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

  static Map<String, dynamic> _metaMap(dynamic metaRaw) {
    if (metaRaw is Map) return JsonCodec.asMap(metaRaw);
    if (metaRaw is String) {
      final text = metaRaw.trim();
      if (text.startsWith('{')) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map) return JsonCodec.asMap(decoded);
        } catch (_) {}
      }
    }
    return const <String, dynamic>{};
  }

  const PortalInboxMapper._();
}
