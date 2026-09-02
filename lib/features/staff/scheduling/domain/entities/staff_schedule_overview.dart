import 'package:flutter/foundation.dart';

import 'staff_shift.dart';
import 'week_day.dart';

/// Aggregate root for everything shown on the "My Schedule" screen.
@immutable
class StaffScheduleOverview {
  final String weekRangeLabel;
  final List<WeekDay> weekDays;
  final String shiftsThisWeekLabel;
  final List<StaffShift> shifts;
  final List<StaffShift> openShiftRequests;

  const StaffScheduleOverview({
    required this.weekRangeLabel,
    required this.weekDays,
    required this.shiftsThisWeekLabel,
    required this.shifts,
    this.openShiftRequests = const [],
  });
}
