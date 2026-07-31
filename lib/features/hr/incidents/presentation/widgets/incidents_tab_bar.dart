import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';

/// Segmented "Open / Under Review / Closed" tab control at the top of the
/// Incidents list screen.
///
/// Per the Figma screenshots, only the "Open" tab ever shows a small count
/// badge, and only while it is *not* the active tab (the active tab's count
/// is already surfaced via the stat tiles below, so repeating it here would
/// be redundant) - "Under Review" and "Closed" never show a badge.
class IncidentsTabBar extends StatelessWidget {
  final IncidentsTab selected;
  final int openBadgeCount;
  final ValueChanged<IncidentsTab> onSelected;

  const IncidentsTabBar({
    super.key,
    required this.selected,
    required this.openBadgeCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: 'Open',
              isActive: selected == IncidentsTab.open,
              badgeCount: selected == IncidentsTab.open ? null : openBadgeCount,
              onTap: () => onSelected(IncidentsTab.open),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: 'Under Review',
              isActive: selected == IncidentsTab.underReview,
              onTap: () => onSelected(IncidentsTab.underReview),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: 'Closed',
              isActive: selected == IncidentsTab.closed,
              onTap: () => onSelected(IncidentsTab.closed),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.05),
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
                  color: isActive ? AppColors.secondaryTeal : AppColors.textSecondary,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: ResponsiveHelper.getResponsiveSize(context, 18),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
                decoration: const BoxDecoration(
                  color: AppColors.criticalBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                    color: AppColors.criticalRed,
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
