import 'package:flutter/foundation.dart';

/// A single day cell in the Calendar tab's week strip, e.g. "Tue 13".
@immutable
class CalendarDay {
  final String dayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool hasShiftIndicator;

  const CalendarDay({
    required this.dayLabel,
    required this.dayNumber,
    this.isSelected = false,
    this.hasShiftIndicator = true,
  });
}
