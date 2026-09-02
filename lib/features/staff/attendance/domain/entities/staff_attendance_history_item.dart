import 'package:flutter/foundation.dart';

/// One row in Attendance History (`workedMinutes` from the API).
@immutable
class StaffAttendanceHistoryItem {
  final String id;
  final String dateLabel;
  final String timeRange;
  final String durationLabel;

  const StaffAttendanceHistoryItem({
    required this.id,
    required this.dateLabel,
    required this.timeRange,
    required this.durationLabel,
  });
}
