import 'package:flutter/foundation.dart';

/// A single day cell in the Calendar tab's week strip, e.g. "Tue 13".
@immutable
class CalendarDay {
  /// Local calendar date for this cell (time stripped).
  final DateTime date;
  final String dayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool hasShiftIndicator;

  const CalendarDay({
    required this.date,
    required this.dayLabel,
    required this.dayNumber,
    this.isSelected = false,
    this.hasShiftIndicator = false,
  });

  CalendarDay copyWith({
    DateTime? date,
    String? dayLabel,
    String? dayNumber,
    bool? isSelected,
    bool? hasShiftIndicator,
  }) {
    return CalendarDay(
      date: date ?? this.date,
      dayLabel: dayLabel ?? this.dayLabel,
      dayNumber: dayNumber ?? this.dayNumber,
      isSelected: isSelected ?? this.isSelected,
      hasShiftIndicator: hasShiftIndicator ?? this.hasShiftIndicator,
    );
  }
}
