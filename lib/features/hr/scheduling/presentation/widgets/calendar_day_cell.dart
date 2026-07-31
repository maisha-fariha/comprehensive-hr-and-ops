import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/calendar_day.dart';
import '../../scheduling_constants.dart';

/// A single day cell in the Calendar tab's week strip, e.g. "Tue 13". The
/// selected day renders its number inside a filled navy circle; every day
/// shows a small dot underneath indicating it has shifts scheduled.
class CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final VoidCallback? onTap;

  const CalendarDayCell({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    final numberBoxSize = ResponsiveHelper.getResponsiveSize(context, 30);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: ResponsiveHelper.getResponsiveWidth(context, SchedulingDimens.calendarDayCellWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.dayLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Container(
              width: numberBoxSize,
              height: numberBoxSize,
              decoration: BoxDecoration(
                color: day.isSelected ? AppColors.primaryNavy : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                day.dayNumber,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: day.isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: day.isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
            SizedBox(
              height: ResponsiveHelper.getResponsiveHeight(context, SchedulingDimens.calendarDayIndicatorSize),
              child: day.hasShiftIndicator
                  ? Container(
                      width: ResponsiveHelper.getResponsiveSize(
                        context,
                        SchedulingDimens.calendarDayIndicatorSize,
                      ),
                      decoration: BoxDecoration(
                        color: day.isSelected ? AppColors.secondaryTeal : AppColors.morningIndicator,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
