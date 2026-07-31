import 'package:flutter/foundation.dart';

/// A single day chip in "My Schedule"'s week navigator, e.g. "Tue 13".
@immutable
class WeekDay {
  final String dayLabel;
  final String dayNumber;
  final bool isSelected;

  const WeekDay({
    required this.dayLabel,
    required this.dayNumber,
    this.isSelected = false,
  });
}
