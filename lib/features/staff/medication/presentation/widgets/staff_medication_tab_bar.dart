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

/// Web-parity tabs: MAR · PRN · Given · Resident chart.
class StaffMedicationTabBar extends StatelessWidget {
  final StaffMedicationTab selectedTab;
  final int marCount;
  final int prnCount;
  final int givenCount;
  final ValueChanged<StaffMedicationTab> onTabSelected;

  static const Color _track = Color(0xFFF1F4F8);
  static const Color _inactiveLabel = Color(0xFF7A869A);
  static const Color _activeBg = Color(0xFF0B1F3A);

  static const Color _marBadgeBg = Color(0xFFE8F6EF);
  static const Color _marBadgeFg = Color(0xFF2D8A56);
  static const Color _prnBadgeBg = Color(0xFFE7F0FF);
  static const Color _prnBadgeFg = Color(0xFF2A5DA6);
  static const Color _givenBadgeBg = Color(0xFFE8F6EF);
  static const Color _givenBadgeFg = Color(0xFF2D8A56);

  const StaffMedicationTabBar({
    super.key,
    required this.selectedTab,
    required this.marCount,
    required this.prnCount,
    required this.givenCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabData(
        tab: StaffMedicationTab.mar,
        label: 'MAR',
        count: marCount,
        badgeBackground: _marBadgeBg,
        badgeForeground: _marBadgeFg,
      ),
      _TabData(
        tab: StaffMedicationTab.prn,
        label: 'PRN',
        count: prnCount,
        badgeBackground: _prnBadgeBg,
        badgeForeground: _prnBadgeFg,
      ),
      _TabData(
        tab: StaffMedicationTab.given,
        label: 'Given',
        count: givenCount,
        badgeBackground: _givenBadgeBg,
        badgeForeground: _givenBadgeFg,
      ),
      const _TabData(
        tab: StaffMedicationTab.residentChart,
        label: 'Resident chart',
      ),
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
    final showCount = data.count != null;
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
          color: isSelected
              ? StaffMedicationTabBar._activeBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
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
                    ? Colors.white
                    : StaffMedicationTabBar._inactiveLabel,
                height: 1.2,
              ),
            ),
            if (showCount) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              if (isSelected)
                Text(
                  '${data.count}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                )
              else
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
