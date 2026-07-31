import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/team_reports_enums.dart';

/// The pill-shaped "Team | Reports | Messages" segmented control shared by
/// all three tabs, with an unread-count badge on the "Messages" segment.
class TeamReportsSegmentedTabs extends StatelessWidget {
  final TeamReportsTab selectedTab;
  final int messagesBadgeCount;
  final ValueChanged<TeamReportsTab> onTabSelected;

  const TeamReportsSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.messagesBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Team',
              isSelected: selectedTab == TeamReportsTab.team,
              onTap: () => onTabSelected(TeamReportsTab.team),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Reports',
              isSelected: selectedTab == TeamReportsTab.reports,
              onTap: () => onTabSelected(TeamReportsTab.reports),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Messages',
              isSelected: selectedTab == TeamReportsTab.messages,
              onTap: () => onTabSelected(TeamReportsTab.messages),
              badgeCount: messagesBadgeCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

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
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.08),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: isSelected ? AppColors.secondaryTeal : AppColors.textMuted,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
              Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: ResponsiveHelper.getResponsiveSize(context, 16),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryTeal,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: Colors.white,
                    height: 1,
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
