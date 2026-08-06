import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/week_day.dart';
import 'day_chip.dart';

/// Week range label with previous/next nav buttons, plus the 7 day chips.
///
/// Chevrons reuse [AppAssets.chevronRight] (previous rotated 180°), in the
/// same bordered rounded-square style as [StaffScheduleHeader].
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
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return Column(
      children: [
        SizedBox(
          height: buttonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonSize + ResponsiveHelper.getResponsiveWidth(context, 10),
                ),
                child: Text(
                  weekRangeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: _NavChevron(rotated: true, onTap: onPreviousWeek),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _NavChevron(rotated: false, onTap: onNextWeek),
              ),
            ],
          ),
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
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final icon = const AppSvgIcon(
      AppAssets.chevronRight,
      size: 18,
      color: AppColors.textHeading,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: rotated ? Transform.rotate(angle: 3.14159, child: icon) : icon,
      ),
    );
  }
}
