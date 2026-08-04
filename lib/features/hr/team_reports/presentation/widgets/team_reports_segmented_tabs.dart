import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/team_reports_enums.dart';

/// Pill segmented control: Team | Reports | Messages, with a soft unread
/// badge on Messages when unselected — matched to the reference.
class TeamReportsSegmentedTabs extends StatelessWidget {
  final TeamReportsTab selectedTab;
  final int messagesBadgeCount;
  final ValueChanged<TeamReportsTab> onTabSelected;

  static const Color _trackBackground = Color(0xFFF1F5F9);
  static const Color _selectedLabel = Color(0xFF0D685E);
  static const Color _unselectedLabel = Color(0xFF718096);
  static const Color _badgeSoft = Color(0xFFD9E7FF);
  static const Color _badgeFg = Color(0xFF1E40AF);

  const TeamReportsSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.messagesBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 3.5),
      decoration: BoxDecoration(
        color: _trackBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
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
              badgeCount: selectedTab == TeamReportsTab.messages
                  ? 0
                  : messagesBadgeCount,
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
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 10,
          horizontal: 4,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: isSelected
                      ? TeamReportsSegmentedTabs._selectedLabel
                      : TeamReportsSegmentedTabs._unselectedLabel,
                  height: 1.1,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 18),
                height: ResponsiveHelper.getResponsiveSize(context, 18),
                decoration: const BoxDecoration(
                  color: TeamReportsSegmentedTabs._badgeSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: TeamReportsSegmentedTabs._badgeFg,
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
