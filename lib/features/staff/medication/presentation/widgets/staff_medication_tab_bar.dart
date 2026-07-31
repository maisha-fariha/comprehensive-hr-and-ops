import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_medication_enums.dart';
import 'staff_medication_count_badge.dart';

class _TabData {
  final StaffMedicationTab tab;
  final String label;
  final int? count;
  final Color badgeBackground;
  final Color badgeForeground;

  const _TabData({
    required this.tab,
    required this.label,
    this.count,
    this.badgeBackground = AppColors.dividerLight,
    this.badgeForeground = AppColors.textMuted,
  });
}

/// The 4-way segmented control shared by every Staff Medication tab: "Due",
/// "Administered N", "Missed N", "Refused". The active segment renders as a
/// raised white pill; inactive segments show a muted label plus a colored
/// count badge where applicable (hidden on the active segment and on the
/// "Due"/"Refused" segments, matching the reference screens).
class StaffMedicationTabBar extends StatelessWidget {
  final StaffMedicationTab selectedTab;
  final int administeredCount;
  final int missedCount;
  final ValueChanged<StaffMedicationTab> onTabSelected;

  const StaffMedicationTabBar({
    super.key,
    required this.selectedTab,
    required this.administeredCount,
    required this.missedCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TabData(tab: StaffMedicationTab.due, label: 'Due'),
      _TabData(
        tab: StaffMedicationTab.administered,
        label: 'Administered',
        count: administeredCount,
        badgeBackground: AppColors.activeBackground,
        badgeForeground: AppColors.activeGreen,
      ),
      _TabData(
        tab: StaffMedicationTab.missed,
        label: 'Missed',
        count: missedCount,
        badgeBackground: AppColors.criticalBackground,
        badgeForeground: AppColors.criticalRed,
      ),
      const _TabData(tab: StaffMedicationTab.refused, label: 'Refused'),
    ];

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
      ),
      child: Row(
        children: [
          for (final data in tabs)
            Expanded(
              child: _TabSegment(
                data: data,
                isSelected: data.tab == selectedTab,
                onTap: () => onTabSelected(data.tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final _TabData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabSegment({required this.data, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 11)),
          boxShadow: isSelected
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: isSelected ? AppColors.secondaryTeal : AppColors.textSecondary,
                ),
              ),
            ),
            if (!isSelected && data.count != null) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              StaffMedicationCountBadge(
                count: data.count!,
                background: data.badgeBackground,
                foreground: data.badgeForeground,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
