import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Small rounded-pill count badge used as a `SectionHeaderRow` trailing
/// widget (e.g. "Submitted Logs [12]", "Missing Logs [4]"). Matches the
/// count pill already established by the Dashboard's "Needs Attention" card
/// header.
class DailyLogCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const DailyLogCountBadge({
    super.key,
    required this.count,
    this.background = AppColors.criticalBackground,
    this.foreground = AppColors.criticalRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19),
      height: ResponsiveHelper.getResponsiveSize(context, 19),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6.4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
        ),
      ),
    );
  }
}
