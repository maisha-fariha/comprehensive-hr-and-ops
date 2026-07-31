import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/week_day.dart';

/// A single day chip in the week navigator, e.g. "Tue 13". The selected day
/// renders its number inside a filled dark-teal circle, per the reference
/// screenshot (the HR Scheduling feature's analogous `CalendarDayCell` uses
/// navy instead — kept distinct here since the Staff portal's screenshot
/// clearly shows a teal fill).
class DayChip extends StatelessWidget {
  final WeekDay day;
  final VoidCallback? onTap;

  const DayChip({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    final numberBoxSize = ResponsiveHelper.getResponsiveSize(context, StaffDimens.dayChipNumberBoxSize);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: ResponsiveHelper.getResponsiveWidth(context, StaffDimens.dayChipWidth),
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
                color: day.isSelected ? AppColors.secondaryTealDark : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                day.dayNumber,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: day.isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: day.isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
