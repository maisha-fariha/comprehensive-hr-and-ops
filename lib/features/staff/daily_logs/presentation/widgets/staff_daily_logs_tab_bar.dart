import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

class _BadgeStyle {
  final Color background;
  final Color foreground;

  const _BadgeStyle(this.background, this.foreground);
}

/// Segmented "My Clients | In Progress | Submitted" control under the
/// Daily Logs app bar — matched to the header + tabs reference screenshot.
class StaffDailyLogsTabBar extends StatelessWidget {
  final StaffDailyLogsTab selectedTab;
  final ValueChanged<StaffDailyLogsTab> onTabSelected;

  static const Color _track = Color(0xFFF1F4F8);
  static const Color _inactiveLabel = Color(0xFF7E8CA0);
  static const Color _activeLabel = Color(0xFF005F56);

  static const int _inProgressBadge = 2;
  static const int _submittedBadge = 5;

  /// Pale blue badge + dark navy count (matches header ink).
  static const _BadgeStyle _inProgressBadgeStyle = _BadgeStyle(
    Color(0xFFE8F0FE),
    Color(0xFF1A2B3C),
  );

  /// Pale mint badge + deep teal count (matches active label).
  static const _BadgeStyle _submittedBadgeStyle = _BadgeStyle(
    Color(0xFFD4F7E5),
    Color(0xFF005F56),
  );

  const StaffDailyLogsTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final segmentRadius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 4,
        bottom: 16,
      ),
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
        decoration: BoxDecoration(
          color: _track,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabSegment(
                label: 'My Clients',
                isActive: selectedTab == StaffDailyLogsTab.myClients,
                radius: segmentRadius,
                onTap: () => onTabSelected(StaffDailyLogsTab.myClients),
              ),
            ),
            Expanded(
              child: _TabSegment(
                label: 'In Progress',
                isActive: selectedTab == StaffDailyLogsTab.inProgress,
                radius: segmentRadius,
                badgeCount: selectedTab == StaffDailyLogsTab.inProgress
                    ? null
                    : _inProgressBadge,
                badgeStyle: _inProgressBadgeStyle,
                onTap: () => onTabSelected(StaffDailyLogsTab.inProgress),
              ),
            ),
            Expanded(
              child: _TabSegment(
                label: 'Submitted',
                isActive: selectedTab == StaffDailyLogsTab.submitted,
                radius: segmentRadius,
                badgeCount: selectedTab == StaffDailyLogsTab.submitted
                    ? null
                    : _submittedBadge,
                badgeStyle: _submittedBadgeStyle,
                onTap: () => onTabSelected(StaffDailyLogsTab.submitted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final double radius;
  final int? badgeCount;
  final _BadgeStyle? badgeStyle;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.isActive,
    required this.radius,
    this.badgeCount,
    this.badgeStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = badgeStyle;
    final count = badgeCount;
    final showBadge = !isActive && count != null && style != null;
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 10,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A2B3C).withValues(alpha: 0.08),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
                    spreadRadius: 0,
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
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: isActive
                      ? StaffDailyLogsTabBar._activeLabel
                      : StaffDailyLogsTabBar._inactiveLabel,
                  height: 1.2,
                ),
              ),
            ),
            if (showBadge) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                    color: style.foreground,
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
