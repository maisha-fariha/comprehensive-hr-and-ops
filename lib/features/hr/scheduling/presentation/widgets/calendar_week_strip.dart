import 'package:flutter/material.dart';

import '../../domain/entities/calendar_day.dart';
import 'calendar_day_cell.dart';

/// The 7-day row (Mon–Sun) beneath the month header on the Calendar tab.
class CalendarWeekStrip extends StatelessWidget {
  final List<CalendarDay> days;
  final ValueChanged<CalendarDay>? onDaySelected;

  const CalendarWeekStrip({super.key, required this.days, this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          CalendarDayCell(
            day: day,
            onTap: onDaySelected == null ? null : () => onDaySelected!(day),
          ),
      ],
    );
  }
}
