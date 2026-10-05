import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_activity_option.dart';

class StaffDailyActivityTabBar extends StatelessWidget {
  final StaffDailyActivityTab selectedTab;
  final ValueChanged<StaffDailyActivityTab> onTabSelected;

  const StaffDailyActivityTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: 'Activity registry',
          selected: selectedTab == StaffDailyActivityTab.registry,
          onTap: () => onTabSelected(StaffDailyActivityTab.registry),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 20)),
        _Tab(
          label: 'Resident history',
          selected: selectedTab == StaffDailyActivityTab.residentHistory,
          onTap: () => onTabSelected(StaffDailyActivityTab.residentHistory),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: selected ? AppColors.textHeading : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 3,
            width: selected ? 28 : 0,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
