import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../scheduling_assets.dart';

/// "May 2025" month label with previous/next navigation buttons, at the top
/// of the Calendar tab's week strip.
///
/// The chevron icon reuses `AppAssets.chevronRight` (rotated 180° for
/// "previous") rather than a dedicated new asset, since no Figma export was
/// available for this build (Figma MCP quota exhausted).
class CalendarMonthHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const CalendarMonthHeader({
    super.key,
    required this.monthLabel,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 34);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthLabel,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: AppColors.textHeading,
          ),
        ),
        Row(
          children: [
            _NavButton(size: buttonSize, onTap: onPreviousMonth, rotated: true),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _NavButton(size: buttonSize, onTap: onNextMonth, rotated: false),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final double size;
  final bool rotated;
  final VoidCallback? onTap;

  const _NavButton({required this.size, required this.rotated, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: rotated ? math.pi : 0,
          child: const AppSvgIcon(SchedulingAssets.monthChevron, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
