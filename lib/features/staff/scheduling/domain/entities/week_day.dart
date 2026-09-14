import 'package:flutter/foundation.dart';

/// A single day chip in "My Schedule"'s week navigator, e.g. "Tue 13".
@immutable
class WeekDay {
  final DateTime date;
  final String dayLabel;
  final String dayNumber;
  final bool isSelected;

  const WeekDay({
    required this.date,
    required this.dayLabel,
    required this.dayNumber,
    this.isSelected = false,
  });

  WeekDay copyWith({bool? isSelected}) {
    return WeekDay(
      date: date,
      dayLabel: dayLabel,
      dayNumber: dayNumber,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
