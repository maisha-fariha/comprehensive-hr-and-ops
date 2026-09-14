import 'package:flutter/foundation.dart';

import 'staff_appointment.dart';
import 'staff_shift.dart';
import 'staff_shift_swap.dart';
import 'week_day.dart';

/// Aggregate root for everything shown on the "My Schedule" screen.
@immutable
class StaffScheduleOverview {
  final String weekRangeLabel;
  final List<WeekDay> weekDays;
  final String shiftsThisWeekLabel;
  final List<StaffShift> shifts;
  final List<StaffShift> openShiftRequests;
  final List<StaffShiftSwap> swapRequests;
  final List<StaffAppointment> appointments;

  /// Non-fatal load issues (open shifts / swaps / appointments failed).
  final List<String> loadWarnings;

  const StaffScheduleOverview({
    required this.weekRangeLabel,
    required this.weekDays,
    required this.shiftsThisWeekLabel,
    required this.shifts,
    this.openShiftRequests = const [],
    this.swapRequests = const [],
    this.appointments = const [],
    this.loadWarnings = const [],
  });

  StaffScheduleOverview copyWith({
    String? weekRangeLabel,
    List<WeekDay>? weekDays,
    String? shiftsThisWeekLabel,
    List<StaffShift>? shifts,
    List<StaffShift>? openShiftRequests,
    List<StaffShiftSwap>? swapRequests,
    List<StaffAppointment>? appointments,
    List<String>? loadWarnings,
  }) {
    return StaffScheduleOverview(
      weekRangeLabel: weekRangeLabel ?? this.weekRangeLabel,
      weekDays: weekDays ?? this.weekDays,
      shiftsThisWeekLabel: shiftsThisWeekLabel ?? this.shiftsThisWeekLabel,
      shifts: shifts ?? this.shifts,
      openShiftRequests: openShiftRequests ?? this.openShiftRequests,
      swapRequests: swapRequests ?? this.swapRequests,
      appointments: appointments ?? this.appointments,
      loadWarnings: loadWarnings ?? this.loadWarnings,
    );
  }
}
