import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';

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

/// Pill segmented control for Medication MAR — matched to the header + tab
/// bar reference (white chrome, soft track, raised selected segment).
class MedicationTabBar extends StatelessWidget {
  final MedicationTab selectedTab;
  final int dueCount;
  final int missedCount;
  final int refusedCount;
  final ValueChanged<MedicationTab> onTabSelected;

  static const Color _trackBackground = Color(0xFFF1F5F9);
  static const Color _selectedLabel = Color(0xFF0D685E);
  static const Color _unselectedLabel = Color(0xFF718096);

  static const Color _dueBadgeBg = Color(0xFFDBEAFE);
  static const Color _dueBadgeFg = Color(0xFF1E40AF);
  static const Color _missedBadgeBg = Color(0xFFFEE2E2);
  static const Color _missedBadgeFg = Color(0xFFB91C1C);
  static const Color _refusedBadgeBg = Color(0xFFFFEDD5);
  static const Color _refusedBadgeFg = Color(0xFF9A3412);

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
        badgeBackground: _dueBadgeBg,
        badgeForeground: _dueBadgeFg,
      ),
      _TabData(
        tab: MedicationTab.missed,
        label: 'Missed',
        count: missedCount,
        badgeBackground: _missedBadgeBg,
        badgeForeground: _missedBadgeFg,
      ),
      _TabData(
        tab: MedicationTab.refused,
        label: 'Refused',
        count: refusedCount,
        badgeBackground: _refusedBadgeBg,
        badgeForeground: _refusedBadgeFg,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 3.5),
      decoration: BoxDecoration(
        color: _trackBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 15),
        ),
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

  const _TabSegment({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 9,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withValues(alpha: 0.08),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  color: isSelected
                      ? MedicationTabBar._selectedLabel
                      : MedicationTabBar._unselectedLabel,
                  height: 1.1,
                ),
              ),
            ),
            if (!isSelected && data.count != null) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              _TabCountBadge(
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

class _TabCountBadge extends StatelessWidget {
  final int count;
  final Color background;
  final Color foreground;

  const _TabCountBadge({
    required this.count,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 17);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}
