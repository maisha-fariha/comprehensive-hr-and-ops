import '../time/tenant_clock.dart';

/// The web portal's date / time formats and shift description, using the
/// organisation timezone from Settings → General ([TenantClock]).
abstract final class WebFormat {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Settings → General date format (default `DD/MM/YYYY`), or with [weekday].
  static String date(DateTime? value, {bool weekday = false, String empty = '—'}) {
    if (value == null) return empty;
    final text = TenantClock.formatDate(value);
    if (text == '—') return empty;
    if (!weekday) return text;
    final l = TenantClock.wallOf(value);
    return '${_weekdays[l.weekday - 1]} $text';
  }

  /// Settings → General time format (`12h` / `24h`).
  static String time(DateTime? value, {String empty = '—'}) {
    if (value == null) return empty;
    final text = TenantClock.formatTime(value);
    return text == '—' ? empty : text;
  }

  /// Date and time in the organisation zone.
  static String dateTime(DateTime? value, {String empty = '—'}) {
    if (value == null) return empty;
    final text = TenantClock.formatDateTime(value);
    return text == '—' ? empty : text;
  }

  /// Time alone when [value] is today (org calendar), otherwise the date.
  static String short(DateTime? value, {DateTime? now, String empty = ''}) {
    if (value == null) return empty;
    final l = TenantClock.wallOf(value);
    final n = now == null ? TenantClock.now() : TenantClock.wallOf(now);
    final today = l.year == n.year && l.month == n.month && l.day == n.day;
    return today ? time(value, empty: empty) : date(value, empty: empty);
  }

  /// `needs_attention` → `Needs attention`; `—` when empty.
  static String humanise(String? value) {
    if (value == null || value.isEmpty) return '—';
    final text = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return text[0].toUpperCase() + text.substring(1);
  }

  /// `Morning — Day shift · Elm House · Tue 29/09/2026 07:00–15:00 · Jamal +1`.
  ///
  /// [staffNames] must already exclude declined and bid-pending assignments.
  /// New Task’s shift dropdown on web omits staff — pass [includeStaff]: false.
  static String describeShift({
    String? shiftType,
    String? title,
    required DateTime? startsAt,
    required DateTime? endsAt,
    List<String> staffNames = const [],
    String? residenceName,
    bool withResidence = false,
    bool includeStaff = true,
  }) {
    final type = shiftType == null || shiftType.isEmpty
        ? null
        : shiftType[0].toUpperCase() + shiftType.substring(1);
    final heading = [type, title]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' — ');
    final who = staffNames.isEmpty
        ? 'nobody rostered'
        : staffNames.length == 1
            ? staffNames.first
            : '${staffNames.first} +${staffNames.length - 1}';
    return [
      heading.isEmpty ? 'Shift' : heading,
      if (withResidence && residenceName != null && residenceName.isNotEmpty)
        residenceName,
      '${date(startsAt, weekday: true, empty: '')} ${time(startsAt)}–${time(endsAt)}',
      if (includeStaff) who,
    ].join(' · ');
  }
}
