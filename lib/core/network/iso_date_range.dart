import '../time/tenant_clock.dart';

/// ISO date helpers for list queries (`from`/`to` and `YYYY-MM-DD`).
///
/// "Today"/week anchors use [TenantClock] (Settings → General timezone).
/// Time labels convert UTC instants via [TenantClock.wallOf]. Calendar-date
/// formatters print the DateTime's fields as-is (pass a wall/calendar value).
abstract final class IsoDateRange {
  static DateTime get _now => TenantClock.now();

  static DateTime get _startOfLocalDay {
    final now = _now;
    return DateTime(now.year, now.month, now.day);
  }

  /// Midnight for a calendar day in the organisation zone.
  static DateTime startOfLocalDay([DateTime? date]) {
    final d = date ?? _now;
    return DateTime(d.year, d.month, d.day);
  }

  static String get todayDate {
    final now = _now;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static String get todayStartIso =>
      TenantClock.at(_startOfLocalDay, 0).toUtc().toIso8601String();

  static String get todayEndIso => TenantClock.at(
        _startOfLocalDay.add(const Duration(days: 1)),
        0,
      ).toUtc().toIso8601String();

  static String formatDisplayDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]} · ${months[date.month - 1]} ${date.day}';
  }

  static String greetingPrefix(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String get nowIso => DateTime.now().toUtc().toIso8601String();

  static String daysAgoStartIso(int days) => TenantClock.at(
        _startOfLocalDay.subtract(Duration(days: days)),
        0,
      ).toUtc().toIso8601String();

  static String workedMinutesLabel(int? minutes) {
    if (minutes == null || minutes < 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? _now;
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime endOfWeek([DateTime? date]) =>
      startOfWeek(date).add(const Duration(days: 7));

  static String get weekStartIso =>
      TenantClock.at(startOfWeek(), 0).toUtc().toIso8601String();

  static String get weekEndIso =>
      TenantClock.at(endOfWeek(), 0).toUtc().toIso8601String();

  static String formatWeekRange(DateTime start, DateTime endInclusive) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (start.month == endInclusive.month && start.year == endInclusive.year) {
      return '${months[start.month - 1]} ${start.day} – ${endInclusive.day}, ${start.year}';
    }
    return '${months[start.month - 1]} ${start.day} – ${months[endInclusive.month - 1]} ${endInclusive.day}, ${endInclusive.year}';
  }

  static String formatShortDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  static String formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String formatWeekdayDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  static String timeAgo(DateTime date) {
    final delta = DateTime.now().toUtc().difference(date.toUtc());
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays == 1) return 'Yesterday';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return formatShortDate(TenantClock.wallOf(date));
  }

  static String formatMonthDay(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String dateTimeLabel(DateTime date) {
    final wall = TenantClock.wallOf(date);
    return '${formatMonthDay(wall)} • ${timeLabel(date)}';
  }

  /// Time of day in the organisation zone (Settings → General).
  static String timeLabel(DateTime date) {
    final formatted = TenantClock.formatTime(date);
    if (formatted == '—') return '';
    return formatted.replaceAll(' am', ' AM').replaceAll(' pm', ' PM');
  }

  static String rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${timeLabel(start)} – ${timeLabel(end)}';
    }
    if (start != null) return timeLabel(start);
    return timeLabel(end!);
  }

  static String elapsedHms(DateTime from) {
    final d = DateTime.now().difference(from);
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String initials(String? name, {String fallback = 'ME'}) {
    final source = (name ?? '').trim();
    if (source.isEmpty) return fallback;
    final parts = source
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return fallback;
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String personName(dynamic value) {
    if (value is Map) {
      final map = value is Map<String, dynamic>
          ? value
          : Map<String, dynamic>.from(value);
      return stringOr(
        map['displayName'] ??
            map['fullName'] ??
            map['name'] ??
            [map['firstName'], map['lastName']]
                .where((p) => p != null && p.toString().trim().isNotEmpty)
                .join(' '),
        'Unknown',
      );
    }
    return stringOr(value, 'Unknown');
  }

  static String stringOr(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  const IsoDateRange._();
}
