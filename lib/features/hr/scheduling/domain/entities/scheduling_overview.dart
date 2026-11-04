import 'package:flutter/foundation.dart';

import 'board_overview.dart';
import 'calendar_schedule.dart';
import 'calendar_shift.dart';
import 'requests_overview.dart';

/// Aggregate root for everything shown on the Manager "Scheduling" screen
/// (its 3 segmented tabs: Calendar, Board and Requests).
@immutable
class SchedulingOverview {
  final CalendarSchedule calendar;
  final BoardOverview board;
  final RequestsOverview requests;

  /// Web summary cards. They always describe the current week, including
  /// while All shifts is showing a different list.
  final WeekShiftCoverage weekCoverage;

  /// Open / bidding shifts (not limited to the visible week) for the web
  /// "Open shifts" rail — upcoming vs past unstaffed.
  final List<CalendarShift> openShifts;

  /// Staff rostered hours for the visible week (web "Staff Rostered Hours").
  final List<StaffRosteredHours> staffRosteredHours;

  const SchedulingOverview({
    required this.calendar,
    required this.board,
    required this.requests,
    this.weekCoverage = WeekShiftCoverage.empty,
    this.openShifts = const [],
    this.staffRosteredHours = const [],
  });

  SchedulingOverview copyWith({
    CalendarSchedule? calendar,
    BoardOverview? board,
    RequestsOverview? requests,
    WeekShiftCoverage? weekCoverage,
    List<CalendarShift>? openShifts,
    List<StaffRosteredHours>? staffRosteredHours,
  }) {
    return SchedulingOverview(
      calendar: calendar ?? this.calendar,
      board: board ?? this.board,
      requests: requests ?? this.requests,
      weekCoverage: weekCoverage ?? this.weekCoverage,
      openShifts: openShifts ?? this.openShifts,
      staffRosteredHours: staffRosteredHours ?? this.staffRosteredHours,
    );
  }
}

/// One assigned shift line under web Staff Rostered Hours → SHIFT BREAKDOWN.
@immutable
class StaffRosteredShiftLine {
  final DateTime startsAt;
  final DateTime endsAt;
  final double hours;
  final String? residenceName;

  const StaffRosteredShiftLine({
    required this.startsAt,
    required this.endsAt,
    required this.hours,
    this.residenceName,
  });
}

/// One row in the web "Staff Rostered Hours" sidebar / modal.
@immutable
class StaffRosteredHours {
  final String staffId;
  final String name;
  final double hours;

  /// Assigned shifts contributing to [hours].
  final int shiftCount;

  /// Per-shift breakdown shown when the staff row is expanded (web modal).
  final List<StaffRosteredShiftLine> shifts;

  const StaffRosteredHours({
    required this.staffId,
    required this.name,
    required this.hours,
    this.shiftCount = 0,
    this.shifts = const [],
  });

  /// Web weekly FTE baseline used for capacity % and overtime.
  static const double weeklyCapacityHours = 40;

  double overtime({required bool monthly, required int daysInMonth}) {
    final capacity = monthly
        ? weeklyCapacityHours * (daysInMonth / 7.0)
        : weeklyCapacityHours;
    final over = hours - capacity;
    return over > 0 ? over : 0;
  }

  double capacityFraction({required bool monthly, required int daysInMonth}) {
    final capacity = monthly
        ? weeklyCapacityHours * (daysInMonth / 7.0)
        : weeklyCapacityHours;
    if (capacity <= 0) return 0;
    return (hours / capacity).clamp(0.0, 1.0);
  }
}

/// The three cards above Week / Month / All shifts.
@immutable
class WeekShiftCoverage {
  final int unstaffed;
  final String unstaffedDescription;
  final String coveredValue;
  final String coveredDescription;
  final String coveredCaption;
  final int openShifts;
  final String openDescription;

  const WeekShiftCoverage({
    required this.unstaffed,
    required this.unstaffedDescription,
    required this.coveredValue,
    required this.coveredDescription,
    required this.coveredCaption,
    required this.openShifts,
    required this.openDescription,
  });

  static const empty = WeekShiftCoverage(
    unstaffed: 0,
    unstaffedDescription: 'Every shift this week has someone assigned',
    coveredValue: '—',
    coveredDescription: 'Nothing on the roster this week yet',
    coveredCaption: 'no shifts',
    openShifts: 0,
    openDescription: 'No shifts are open for staff to bid on',
  );
}
