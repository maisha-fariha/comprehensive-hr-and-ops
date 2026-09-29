/// The web portal's date / time formats (DD/MM/YYYY, 24h, local clock) and
/// its one-line shift description, shared by features that mirror web screens.
abstract final class WebFormat {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// `29/09/2026`, or `Tue 29/09/2026` with [weekday].
  static String date(DateTime? value, {bool weekday = false, String empty = '—'}) {
    if (value == null) return empty;
    final l = value.toLocal();
    final text = '${_two(l.day)}/${_two(l.month)}/${l.year}';
    return weekday ? '${_weekdays[l.weekday - 1]} $text' : text;
  }

  /// `14:05`.
  static String time(DateTime? value, {String empty = '—'}) {
    if (value == null) return empty;
    final l = value.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  /// `29/09/2026 14:05`.
  static String dateTime(DateTime? value, {String empty = '—'}) =>
      value == null ? empty : '${date(value)} ${time(value)}';

  /// Time alone when [value] is today, otherwise the date.
  static String short(DateTime? value, {DateTime? now, String empty = ''}) {
    if (value == null) return empty;
    final l = value.toLocal();
    final n = (now ?? DateTime.now()).toLocal();
    final today = l.year == n.year && l.month == n.month && l.day == n.day;
    return today ? time(l) : date(l);
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
  static String describeShift({
    String? shiftType,
    String? title,
    required DateTime? startsAt,
    required DateTime? endsAt,
    List<String> staffNames = const [],
    String? residenceName,
    bool withResidence = false,
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
      who,
    ].join(' · ');
  }
}
