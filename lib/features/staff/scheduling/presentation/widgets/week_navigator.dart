import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/week_day.dart';
import 'day_chip.dart';

/// The "‹ May 12 – May 18, 2025 ›" week label + navigation chevrons, and the
/// row of 7 day chips beneath it.
///
/// Both chevrons reuse the existing `AppAssets.chevronRight` SVG (the
/// "previous" one rotated 180°), the same convention as the HR Scheduling
/// feature's `SchedulingAssets.monthChevron`.
class WeekNavigator extends StatelessWidget {
  final String weekRangeLabel;
  final List<WeekDay> days;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final ValueChanged<WeekDay>? onDaySelected;

  const WeekNavigator({
    super.key,
    required this.weekRangeLabel,
    required this.days,
    this.onPreviousWeek,
    this.onNextWeek,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavChevron(rotated: true, onTap: onPreviousWeek),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Text(
              weekRangeLabel,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            _NavChevron(rotated: false, onTap: onNextWeek),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final day in days)
              DayChip(
                day: day,
                onTap: onDaySelected == null ? null : () => onDaySelected!(day),
              ),
          ],
        ),
      ],
    );
  }
}

class _NavChevron extends StatelessWidget {
  final bool rotated;
  final VoidCallback? onTap;

  const _NavChevron({required this.rotated, this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = AppSvgIcon(AppAssets.chevronRight, size: 15, color: AppColors.textSecondary);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: ResponsiveHelper.getResponsiveSize(context, 24),
        height: ResponsiveHelper.getResponsiveSize(context, 24),
        child: Center(
          child: rotated ? Transform.rotate(angle: 3.14159, child: icon) : icon,
        ),
      ),
    );
  }
}
