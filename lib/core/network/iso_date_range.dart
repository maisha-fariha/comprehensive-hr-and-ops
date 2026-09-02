/// ISO date helpers for list queries (`from`/`to` and `YYYY-MM-DD`).
abstract final class IsoDateRange {
  static DateTime get _startOfLocalDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String get todayDate {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static String get todayStartIso => _startOfLocalDay.toUtc().toIso8601String();

  static String get todayEndIso =>
      _startOfLocalDay.add(const Duration(days: 1)).toUtc().toIso8601String();

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

  static String daysAgoStartIso(int days) =>
      _startOfLocalDay.subtract(Duration(days: days)).toUtc().toIso8601String();

  static String workedMinutesLabel(int? minutes) {
    if (minutes == null || minutes < 0) return '';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime endOfWeek([DateTime? date]) =>
      startOfWeek(date).add(const Duration(days: 7));

  static String get weekStartIso => startOfWeek().toUtc().toIso8601String();

  static String get weekEndIso => endOfWeek().toUtc().toIso8601String();

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

  static String timeLabel(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $suffix';
  }

  static String rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${timeLabel(start.toLocal())} – ${timeLabel(end.toLocal())}';
    }
    if (start != null) return timeLabel(start.toLocal());
    return timeLabel(end!.toLocal());
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
