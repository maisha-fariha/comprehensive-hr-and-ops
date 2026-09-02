import 'package:flutter/foundation.dart';

import 'attendance_stat.dart';
import 'late_arrival_entry.dart';
import 'missed_clock_in_entry.dart';
import 'overtime_entry.dart';
import 'staff_status_entry.dart';

/// Aggregate root for everything shown on the "Attendance" screen, across
/// its 4 segmented tabs ("Today" / "Late" / "Missed" / "OT").
@immutable
class AttendanceOverview {
  // Tab badge counts shown on the segmented control when a tab is inactive.
  final int lateCount;
  final int missedCount;
  final int otCount;

  // "Today" tab.
  final List<AttendanceStat> todayStats;
  final String staffOnDutyLabel;
  final List<StaffStatusEntry> staffStatus;

  // "Late" tab.
  final List<AttendanceStat> lateStats;
  final List<LateArrivalEntry> lateArrivals;

  // "Missed" tab.
  final List<AttendanceStat> missedStats;
  final List<MissedClockInEntry> missedClockIns;

  // "OT" tab.
  final List<AttendanceStat> otStats;
  final List<OvertimeEntry> overtimeEntries;

  final String? geofenceResidenceName;
  final String? geofenceRadiusLabel;

  const AttendanceOverview({
    required this.lateCount,
    required this.missedCount,
    required this.otCount,
    required this.todayStats,
    required this.staffOnDutyLabel,
    required this.staffStatus,
    required this.lateStats,
    required this.lateArrivals,
    required this.missedStats,
    required this.missedClockIns,
    required this.otStats,
    required this.overtimeEntries,
    this.geofenceResidenceName,
    this.geofenceRadiusLabel,
  });
}
