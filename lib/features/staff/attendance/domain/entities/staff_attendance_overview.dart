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
  final DateTime? checkInAt;
  final bool isWithinGeofence;
  final String geofenceStatusLabel;
  final String geofenceAddress;
  final bool isSelfieVerified;
  final String selfieVerifiedLabel;
  final String? selfieUrl;
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
    this.checkInAt,
    required this.isWithinGeofence,
    required this.geofenceStatusLabel,
    required this.geofenceAddress,
    required this.isSelfieVerified,
    required this.selfieVerifiedLabel,
    this.selfieUrl,
    required this.isOnBreak,
    required this.breakStatusLabel,
    this.shiftId,
    this.residenceId,
    this.history = const [],
  });

  StaffAttendanceOverview copyWith({
    String? elapsedTimeLabel,
    bool? isOnBreak,
    String? breakStatusLabel,
  }) {
    return StaffAttendanceOverview(
      isOnShift: isOnShift,
      shiftStartedLabel: shiftStartedLabel,
      shiftLocationName: shiftLocationName,
      shiftTimeRange: shiftTimeRange,
      elapsedTimeLabel: elapsedTimeLabel ?? this.elapsedTimeLabel,
      checkInAt: checkInAt,
      isWithinGeofence: isWithinGeofence,
      geofenceStatusLabel: geofenceStatusLabel,
      geofenceAddress: geofenceAddress,
      isSelfieVerified: isSelfieVerified,
      selfieVerifiedLabel: selfieVerifiedLabel,
      selfieUrl: selfieUrl,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStatusLabel: breakStatusLabel ?? this.breakStatusLabel,
      shiftId: shiftId,
      residenceId: residenceId,
      history: history,
    );
  }
}
