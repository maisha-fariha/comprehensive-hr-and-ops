import 'package:flutter/foundation.dart';

import 'staff_attendance_history_item.dart';
import 'staff_attendance_metrics.dart';

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

  /// When true, clock-in is only allowed inside [geofenceRadiusMeters].
  final bool geofenceEnabled;
  final double? geofenceLatitude;
  final double? geofenceLongitude;
  final double? geofenceRadiusMeters;
  final bool isSelfieVerified;
  final String selfieVerifiedLabel;
  final String? selfieUrl;
  final bool isOnBreak;
  final String breakStatusLabel;

  /// When the current break started (wall clock). Null when not on break.
  final DateTime? breakStartedAt;

  /// Completed unpaid break minutes on the open punch (web Worked "Xm break").
  final int breakMinutes;
  final String? shiftId;
  final String? residenceId;

  /// Scheduled end of the shift being clocked out. Null when none is rostered.
  final DateTime? shiftEndsAt;

  /// Start of the current or next rostered shift. Null when none is in the
  /// web clock-in window.
  final DateTime? shiftStartsAt;
  final bool hasRosteredShiftNow;
  final StaffAttendanceMetrics metrics;
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
    this.geofenceEnabled = false,
    this.geofenceLatitude,
    this.geofenceLongitude,
    this.geofenceRadiusMeters,
    required this.isSelfieVerified,
    required this.selfieVerifiedLabel,
    this.selfieUrl,
    required this.isOnBreak,
    required this.breakStatusLabel,
    this.breakStartedAt,
    this.breakMinutes = 0,
    this.shiftId,
    this.residenceId,
    this.shiftEndsAt,
    this.shiftStartsAt,
    this.hasRosteredShiftNow = false,
    this.metrics = StaffAttendanceMetrics.empty,
    this.history = const [],
  });

  StaffAttendanceOverview copyWith({
    String? elapsedTimeLabel,
    bool? isOnBreak,
    String? breakStatusLabel,
    DateTime? breakStartedAt,
    int? breakMinutes,
    bool? isWithinGeofence,
    String? geofenceStatusLabel,
    String? geofenceAddress,
  }) {
    return StaffAttendanceOverview(
      isOnShift: isOnShift,
      shiftStartedLabel: shiftStartedLabel,
      shiftLocationName: shiftLocationName,
      shiftTimeRange: shiftTimeRange,
      elapsedTimeLabel: elapsedTimeLabel ?? this.elapsedTimeLabel,
      checkInAt: checkInAt,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      geofenceStatusLabel: geofenceStatusLabel ?? this.geofenceStatusLabel,
      geofenceAddress: geofenceAddress ?? this.geofenceAddress,
      geofenceEnabled: geofenceEnabled,
      geofenceLatitude: geofenceLatitude,
      geofenceLongitude: geofenceLongitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      isSelfieVerified: isSelfieVerified,
      selfieVerifiedLabel: selfieVerifiedLabel,
      selfieUrl: selfieUrl,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStatusLabel: breakStatusLabel ?? this.breakStatusLabel,
      breakStartedAt: breakStartedAt ?? this.breakStartedAt,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      shiftId: shiftId,
      residenceId: residenceId,
      shiftEndsAt: shiftEndsAt,
      shiftStartsAt: shiftStartsAt,
      hasRosteredShiftNow: hasRosteredShiftNow,
      metrics: metrics,
      history: history,
    );
  }

  /// True when GPS tracking is on and the residence has a usable fence.
  bool get requiresGeofence =>
      geofenceEnabled &&
      geofenceLatitude != null &&
      geofenceLongitude != null &&
      (geofenceRadiusMeters ?? 0) > 0;
}
