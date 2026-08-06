import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../staff_core_constants.dart';
import '../../domain/entities/week_day.dart';

/// A single day chip in the week navigator, e.g. "Tue" / "13".
///
/// Selected: teal rounded rectangle with white day + date.
/// Unselected: muted day label + dark navy date, no background.
class DayChip extends StatelessWidget {
  final WeekDay day;
  final VoidCallback? onTap;

  const DayChip({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = day.isSelected;
    final width = ResponsiveHelper.getResponsiveWidth(context, StaffDimens.dayChipWidth);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: width,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 10,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.dayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                color: selected ? Colors.white : AppColors.textFaint,
                height: 1.1,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              day.dayNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: selected ? Colors.white : AppColors.textHeading,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
