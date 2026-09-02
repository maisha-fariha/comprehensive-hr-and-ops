import 'package:flutter/foundation.dart';

import 'staff_attendance_history_item.dart';

/// Aggregate root for everything shown on the "Attendance" screen.
@immutable
class StaffAttendanceOverview {
  final bool isOnShift;
  final String shiftStartedLabel;
  final String shiftLocationName;
  final String shiftTimeRange;
  final String elapsedTimeLabel;
  final bool isWithinGeofence;
  final String geofenceAddress;
  final bool isSelfieVerified;
  final String selfieVerifiedLabel;
  final bool isOnBreak;
  final String breakStatusLabel;
  final String? shiftId;
  final String? residenceId;
  final List<StaffAttendanceHistoryItem> history;

  const StaffAttendanceOverview({
    required this.isOnShift,
    required this.shiftStartedLabel,
    required this.shiftLocationName,
    required this.shiftTimeRange,
    required this.elapsedTimeLabel,
    required this.isWithinGeofence,
    required this.geofenceAddress,
    required this.isSelfieVerified,
    required this.selfieVerifiedLabel,
    required this.isOnBreak,
    required this.breakStatusLabel,
    this.shiftId,
    this.residenceId,
    this.history = const [],
  });
}
