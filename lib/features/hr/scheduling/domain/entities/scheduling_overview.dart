import 'package:flutter/foundation.dart';

import 'board_overview.dart';
import 'calendar_schedule.dart';
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

  const SchedulingOverview({
    required this.calendar,
    required this.board,
    required this.requests,
    this.weekCoverage = WeekShiftCoverage.empty,
  });

  SchedulingOverview copyWith({
    CalendarSchedule? calendar,
    BoardOverview? board,
    RequestsOverview? requests,
    WeekShiftCoverage? weekCoverage,
  }) {
    return SchedulingOverview(
      calendar: calendar ?? this.calendar,
      board: board ?? this.board,
      requests: requests ?? this.requests,
      weekCoverage: weekCoverage ?? this.weekCoverage,
    );
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
