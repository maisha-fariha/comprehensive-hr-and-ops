import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

/// Web-parity tabs: To review · Missing · Resident day view · House activity.
class StaffDailyLogsTabBar extends StatelessWidget {
  final StaffDailyLogsTab selectedTab;
  final ValueChanged<StaffDailyLogsTab> onTabSelected;
  final int toReviewCount;
  final int missingCount;

  const StaffDailyLogsTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.toReviewCount = 0,
    this.missingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        bottom: 12,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'To review',
              selected: selectedTab == StaffDailyLogsTab.toReview,
              badge: toReviewCount,
              onTap: () => onTabSelected(StaffDailyLogsTab.toReview),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _Chip(
              label: 'Missing',
              selected: selectedTab == StaffDailyLogsTab.missing,
              badge: missingCount,
              onTap: () => onTabSelected(StaffDailyLogsTab.missing),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _Chip(
              label: 'Resident day view',
              selected: selectedTab == StaffDailyLogsTab.residentDay,
              onTap: () => onTabSelected(StaffDailyLogsTab.residentDay),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _Chip(
              label: 'House activity',
              selected: selectedTab == StaffDailyLogsTab.houseActivity,
              onTap: () => onTabSelected(StaffDailyLogsTab.houseActivity),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EEF2) : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFD5DEE6) : AppColors.searchBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: selected
                    ? AppColors.textHeading
                    : AppColors.textSecondary,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.secondaryTeal
                      : AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: selected ? Colors.white : AppColors.textSecondary,
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
