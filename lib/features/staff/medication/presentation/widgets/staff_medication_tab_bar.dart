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

/// Horizontally scrollable segmented control for Medication MAR tabs.
///
/// Active segment: raised white pill + teal label.
/// Inactive: muted label + count badge (Administered / Missed).
class StaffMedicationTabBar extends StatelessWidget {
  final StaffMedicationTab selectedTab;
  final int administeredCount;
  final int missedCount;
  final ValueChanged<StaffMedicationTab> onTabSelected;

  static const Color _track = Color(0xFFF1F4F8);
  static const Color _inactiveLabel = Color(0xFF7A869A);
  static const Color _activeLabel = Color(0xFF005F56);

  /// Pale blue badge for Administered count.
  static const Color _administeredBadgeBg = Color(0xFFE7F0FF);
  static const Color _administeredBadgeFg = Color(0xFF2A5DA6);

  /// Pale peach badge for Missed count.
  static const Color _missedBadgeBg = Color(0xFFFFF0D8);
  static const Color _missedBadgeFg = Color(0xFFDE7A00);

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
        badgeBackground: _administeredBadgeBg,
        badgeForeground: _administeredBadgeFg,
      ),
      _TabData(
        tab: StaffMedicationTab.missed,
        label: 'Missed',
        count: missedCount,
        badgeBackground: _missedBadgeBg,
        badgeForeground: _missedBadgeFg,
      ),
      const _TabData(tab: StaffMedicationTab.refused, label: 'Refused'),
    ];

    final trackRadius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final segmentRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final data in tabs)
              _TabSegment(
                data: data,
                isSelected: data.tab == selectedTab,
                radius: segmentRadius,
                onTap: () => onTabSelected(data.tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final _TabData data;
  final bool isSelected;
  final double radius;
  final VoidCallback onTap;

  const _TabSegment({
    required this.data,
    required this.isSelected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.06),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: isSelected
                    ? StaffMedicationTabBar._activeLabel
                    : StaffMedicationTabBar._inactiveLabel,
                height: 1.2,
              ),
            ),
            if (!isSelected && data.count != null) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
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
