import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';
import 'medication_count_badge.dart';

class _TabData {
  final MedicationTab tab;
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

/// The 4-way segmented control shared by every Medication tab: "Overview",
/// "Due N", "Missed N", "Refused N". The active segment renders as a raised
/// white pill; inactive segments show a muted label plus a colored count
/// badge (hidden on the active segment, matching the reference screens).
class MedicationTabBar extends StatelessWidget {
  final MedicationTab selectedTab;
  final int dueCount;
  final int missedCount;
  final int refusedCount;
  final ValueChanged<MedicationTab> onTabSelected;

  const MedicationTabBar({
    super.key,
    required this.selectedTab,
    required this.dueCount,
    required this.missedCount,
    required this.refusedCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TabData(tab: MedicationTab.overview, label: 'Overview'),
      _TabData(
        tab: MedicationTab.due,
        label: 'Due',
        count: dueCount,
        badgeBackground: AppColors.infoBackground,
        badgeForeground: AppColors.infoBlue,
      ),
      _TabData(
        tab: MedicationTab.missed,
        label: 'Missed',
        count: missedCount,
        badgeBackground: AppColors.criticalBackground,
        badgeForeground: AppColors.criticalRed,
      ),
      _TabData(
        tab: MedicationTab.refused,
        label: 'Refused',
        count: refusedCount,
        badgeBackground: AppColors.urgentBackground,
        badgeForeground: AppColors.urgentAmber,
      ),
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
              MedicationCountBadge(
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
