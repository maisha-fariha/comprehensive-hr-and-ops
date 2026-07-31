import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_logs_enums.dart';

/// Segmented "Review | Missing | Handover" tab control shown beneath the
/// Daily Logs app bar. The active segment renders as a white, slightly
/// elevated pill on a light-gray track; inactive segments are plain text.
class DailyLogsTabBar extends StatelessWidget {
  final DailyLogsTab selectedTab;
  final int missingBadgeCount;
  final ValueChanged<DailyLogsTab> onTabSelected;

  const DailyLogsTabBar({
    super.key,
    required this.selectedTab,
    required this.missingBadgeCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, bottom: 16),
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabSegment(
              label: 'Review',
              isActive: selectedTab == DailyLogsTab.review,
              onTap: () => onTabSelected(DailyLogsTab.review),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Missing',
              isActive: selectedTab == DailyLogsTab.missing,
              badgeCount: selectedTab == DailyLogsTab.missing ? null : missingBadgeCount,
              onTap: () => onTabSelected(DailyLogsTab.missing),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Handover',
              isActive: selectedTab == DailyLogsTab.handover,
              onTap: () => onTabSelected(DailyLogsTab.handover),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.isActive,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 11)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.06),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Text(
                '$badgeCount',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.criticalRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
