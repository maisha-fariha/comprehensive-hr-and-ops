import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../staff_daily_logs_constants.dart';

/// Segmented "My Clients | In Progress | Submitted" tab control shown
/// beneath the Daily Logs app bar. The active segment renders as a white,
/// slightly elevated pill on a light-gray track; inactive segments show a
/// small teal count pill next to their label (per the reference
/// screenshots, each tab shows its own count only while inactive).
class StaffDailyLogsTabBar extends StatelessWidget {
  final StaffDailyLogsTab selectedTab;
  final int myClientsCount;
  final int inProgressCount;
  final int submittedCount;
  final ValueChanged<StaffDailyLogsTab> onTabSelected;

  const StaffDailyLogsTabBar({
    super.key,
    required this.selectedTab,
    required this.myClientsCount,
    required this.inProgressCount,
    required this.submittedCount,
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
              label: 'My Clients',
              isActive: selectedTab == StaffDailyLogsTab.myClients,
              badgeCount: selectedTab == StaffDailyLogsTab.myClients ? null : myClientsCount,
              onTap: () => onTabSelected(StaffDailyLogsTab.myClients),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'In Progress',
              isActive: selectedTab == StaffDailyLogsTab.inProgress,
              badgeCount: selectedTab == StaffDailyLogsTab.inProgress ? null : inProgressCount,
              onTap: () => onTabSelected(StaffDailyLogsTab.inProgress),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Submitted',
              isActive: selectedTab == StaffDailyLogsTab.submitted,
              badgeCount: selectedTab == StaffDailyLogsTab.submitted ? null : submittedCount,
              onTap: () => onTabSelected(StaffDailyLogsTab.submitted),
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
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 9, horizontal: 4),
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Container(
                constraints: const BoxConstraints(minWidth: 17),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
                decoration: BoxDecoration(
                  color: StaffDailyLogsConstants.tabBadgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                    color: StaffDailyLogsConstants.tabBadgeForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
