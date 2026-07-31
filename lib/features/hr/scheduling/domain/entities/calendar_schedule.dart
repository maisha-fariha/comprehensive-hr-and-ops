import 'package:flutter/foundation.dart';

import 'calendar_day.dart';
import 'calendar_shift.dart';

/// Aggregate for everything shown on the Calendar tab.
@immutable
class CalendarSchedule {
  final String monthLabel;
  final List<CalendarDay> days;
  final String selectedDateLabel;
  final String shiftsSummaryLabel;
  final String openShiftsLabel;
  final List<CalendarShift> shifts;

  const CalendarSchedule({
    required this.monthLabel,
    required this.days,
    required this.selectedDateLabel,
    required this.shiftsSummaryLabel,
    required this.openShiftsLabel,
    required this.shifts,
  });
}
