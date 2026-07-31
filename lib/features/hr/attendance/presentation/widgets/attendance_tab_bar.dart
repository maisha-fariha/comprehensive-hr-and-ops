import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../attendance_constants.dart';
import '../../domain/entities/attendance_enums.dart';

class _TabSpec {
  final AttendanceTab tab;
  final String label;
  final int? badgeCount;

  const _TabSpec({required this.tab, required this.label, this.badgeCount});
}

/// The segmented control shared by every Attendance tab: "Today | Late 3 |
/// Missed 1 | OT 2". The active segment renders as a white rounded pill;
/// inactive segments show a small numeric badge next to their label (hidden
/// on whichever tab is currently active, matching the reference
/// screenshots).
class AttendanceTabBar extends StatelessWidget {
  final AttendanceTab selected;
  final int lateCount;
  final int missedCount;
  final int otCount;
  final ValueChanged<AttendanceTab> onSelected;

  const AttendanceTabBar({
    super.key,
    required this.selected,
    required this.lateCount,
    required this.missedCount,
    required this.otCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final specs = [
      const _TabSpec(tab: AttendanceTab.today, label: 'Today'),
      _TabSpec(tab: AttendanceTab.late, label: 'Late', badgeCount: lateCount),
      _TabSpec(tab: AttendanceTab.missed, label: 'Missed', badgeCount: missedCount),
      _TabSpec(tab: AttendanceTab.ot, label: 'OT', badgeCount: otCount),
    ];

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, bottom: 16),
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, AttendanceDimens.tabBarHeight),
        padding: ResponsiveHelper.getResponsivePadding(context, all: 3),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AttendanceDimens.tabBarRadius),
          ),
        ),
        child: Row(
          children: [
            for (final spec in specs)
              Expanded(
                child: _TabSegment(
                  spec: spec,
                  isActive: spec.tab == selected,
                  onTap: () => onSelected(spec.tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final _TabSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _TabSegment({required this.spec, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showBadge = !isActive && (spec.badgeCount ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveWidth(context, 2)),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AttendanceDimens.tabBarRadius - 2),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.08),
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
              spec.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (showBadge) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: ResponsiveHelper.getResponsiveSize(context, 16),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 4),
                decoration: BoxDecoration(
                  color: spec.tab == AttendanceTab.missed
                      ? AppColors.criticalBackground
                      : AppColors.urgentBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${spec.badgeCount}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: spec.tab == AttendanceTab.missed ? AppColors.criticalRed : AppColors.urgentAmber,
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
