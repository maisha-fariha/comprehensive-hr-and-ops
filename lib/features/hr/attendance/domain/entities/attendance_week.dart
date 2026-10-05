/// A Monday–Sunday week, the unit the Attendance date filter works in.
class AttendanceWeek {
  final DateTime start;

  AttendanceWeek._(this.start);

  factory AttendanceWeek.containing(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return AttendanceWeek._(day.subtract(Duration(days: day.weekday - 1)));
  }

  DateTime get end => DateTime(start.year, start.month, start.day + 6);

  AttendanceWeek get previous =>
      AttendanceWeek._(DateTime(start.year, start.month, start.day - 7));

  AttendanceWeek get next =>
      AttendanceWeek._(DateTime(start.year, start.month, start.day + 7));

  String get from => _isoDate(start);

  String get to => _isoDate(end);

  /// e.g. "28 Sep – 4 Oct 2026".
  String get label =>
      '${start.day} ${_months[start.month - 1]} – '
      '${end.day} ${_months[end.month - 1]} ${end.year}';

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is AttendanceWeek && other.start == start;

  @override
  int get hashCode => start.hashCode;

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const _months = [
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
}
