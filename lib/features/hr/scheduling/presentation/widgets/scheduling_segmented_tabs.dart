import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../scheduling_constants.dart';

/// The "Calendar | Board | Requests" segmented control shared by all 3
/// Scheduling tabs. The active segment renders as a white, shadowed pill on
/// top of a light gray track; the "Requests" segment additionally carries a
/// small pending-count badge.
class SchedulingSegmentedTabs extends StatelessWidget {
  final SchedulingTab selectedTab;
  final int requestsBadgeCount;
  final ValueChanged<SchedulingTab> onTabSelected;

  const SchedulingSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.requestsBadgeCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: SchedulingDimens.screenPaddingHorizontal,
        bottom: 14,
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, SchedulingDimens.segmentedTabTrackHeight),
        padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusInput),
          ),
        ),
        child: Row(
          children: [
            _Segment(
              label: 'Calendar',
              isActive: selectedTab == SchedulingTab.calendar,
              onTap: () => onTabSelected(SchedulingTab.calendar),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
            _Segment(
              label: 'Board',
              isActive: selectedTab == SchedulingTab.board,
              onTap: () => onTabSelected(SchedulingTab.board),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
            _Segment(
              label: 'Requests',
              isActive: selectedTab == SchedulingTab.requests,
              badgeCount: requestsBadgeCount,
              onTap: () => onTabSelected(SchedulingTab.requests),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isActive,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusChip),
            ),
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
                  color: isActive ? AppColors.textHeading : AppColors.textMuted,
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.criticalRed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
