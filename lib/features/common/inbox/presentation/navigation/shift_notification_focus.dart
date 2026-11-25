import '../../domain/entities/portal_notification.dart';

/// Date + shift id carried from a scheduling notification into My Schedule.
class ShiftNotificationFocus {
  final DateTime? date;
  final String? shiftId;

  const ShiftNotificationFocus({this.date, this.shiftId});

  bool get isEmpty => date == null && (shiftId == null || shiftId!.isEmpty);

  /// Reads `meta.shiftStartsAt` / `entityId` (and common aliases) from a bell
  /// or push payload so Schedule can jump to that day.
  static ShiftNotificationFocus fromNotification(PortalNotification n) {
    final shiftId = _nonEmpty(n.meta['shiftId']) ??
        _nonEmpty(n.entityId) ??
        _nonEmpty(n.meta['entityId']);
    final raw = n.meta['shiftStartsAt'] ??
        n.meta['startsAt'] ??
        n.meta['startAt'] ??
        n.meta['shiftStart'];
    final parsed = _parseDay(raw);
    return ShiftNotificationFocus(date: parsed, shiftId: shiftId);
  }

  static ShiftNotificationFocus fromPushData(Map<String, dynamic> data) {
    final shiftId = _nonEmpty(data['shiftId']) ??
        _nonEmpty(data['entityId']) ??
        _nonEmpty(data['id']);
    final raw = data['shiftStartsAt'] ??
        data['startsAt'] ??
        data['startAt'] ??
        data['shiftStart'];
    return ShiftNotificationFocus(date: _parseDay(raw), shiftId: shiftId);
  }

  static DateTime? _parseDay(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      final local = raw.toLocal();
      return DateTime(local.year, local.month, local.day);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return text;
  }
}
