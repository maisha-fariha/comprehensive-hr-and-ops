import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_enums.dart';

class _BadgeStyle {
  final Color background;
  final Color foreground;

  const _BadgeStyle(this.background, this.foreground);
}

/// Segmented "My Incidents / All Incidents" control — same visual language as
/// [StaffDailyLogsTabBar] (slate track, white elevated segment, mint badge).
class StaffIncidentsTabBar extends StatelessWidget {
  final StaffIncidentsTab selected;

  /// Kept for call-site compatibility; badge count is UI-hardcoded to 3.
  final int totalCount;
  final ValueChanged<StaffIncidentsTab> onSelected;

  static const Color _track = Color(0xFFF1F4F8);
  static const Color _inactiveLabel = Color(0xFF7E8CA0);
  static const Color _activeLabel = Color(0xFF005F56);

  static const int _allIncidentsBadge = 3;

  /// Pale mint badge + deep teal count (matches Daily Logs Submitted badge).
  static const _BadgeStyle _allBadgeStyle = _BadgeStyle(
    Color(0xFFD4F7E5),
    Color(0xFF005F56),
  );

  const StaffIncidentsTabBar({
    super.key,
    required this.selected,
    required this.totalCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final segmentRadius = ResponsiveHelper.getResponsiveRadius(context, 8);

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
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabSegment(
                label: 'My Incidents',
                isActive: selected == StaffIncidentsTab.myIncidents,
                radius: segmentRadius,
                onTap: () => onSelected(StaffIncidentsTab.myIncidents),
              ),
            ),
            Expanded(
              child: _TabSegment(
                label: 'All Incidents',
                isActive: selected == StaffIncidentsTab.allIncidents,
                radius: segmentRadius,
                badgeCount: selected == StaffIncidentsTab.allIncidents
                    ? null
                    : _allIncidentsBadge,
                badgeStyle: _allBadgeStyle,
                onTap: () => onSelected(StaffIncidentsTab.allIncidents),
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
                      ? StaffIncidentsTabBar._activeLabel
                      : StaffIncidentsTabBar._inactiveLabel,
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
