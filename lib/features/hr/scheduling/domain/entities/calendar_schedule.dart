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

  /// Shifts for the currently selected day (timeline below the week strip).
  final List<CalendarShift> shifts;

  /// All mapped shifts in the loaded week — used to rematerialize the
  /// calendar when the user taps another day without refetching.
  final List<CalendarShift> weekShifts;

  const CalendarSchedule({
    required this.monthLabel,
    required this.days,
    required this.selectedDateLabel,
    required this.shiftsSummaryLabel,
    required this.openShiftsLabel,
    required this.shifts,
    this.weekShifts = const [],
  });

  CalendarSchedule copyWith({
    String? monthLabel,
    List<CalendarDay>? days,
    String? selectedDateLabel,
    String? shiftsSummaryLabel,
    String? openShiftsLabel,
    List<CalendarShift>? shifts,
    List<CalendarShift>? weekShifts,
  }) {
    return CalendarSchedule(
      monthLabel: monthLabel ?? this.monthLabel,
      days: days ?? this.days,
      selectedDateLabel: selectedDateLabel ?? this.selectedDateLabel,
      shiftsSummaryLabel: shiftsSummaryLabel ?? this.shiftsSummaryLabel,
      openShiftsLabel: openShiftsLabel ?? this.openShiftsLabel,
      shifts: shifts ?? this.shifts,
      weekShifts: weekShifts ?? this.weekShifts,
    );
  }
}
