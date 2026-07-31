import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_incidents_enums.dart';

/// Segmented "My Incidents / All Incidents" tab control at the top of the
/// Staff Incidents list screen. Both source screenshots show a small count
/// badge on whichever tab is *not* active (the same 3 incidents back both
/// tabs), so [totalCount] is shown next to the inactive tab's label.
class StaffIncidentsTabBar extends StatelessWidget {
  final StaffIncidentsTab selected;
  final int totalCount;
  final ValueChanged<StaffIncidentsTab> onSelected;

  const StaffIncidentsTabBar({
    super.key,
    required this.selected,
    required this.totalCount,
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
              label: 'My Incidents',
              isActive: selected == StaffIncidentsTab.myIncidents,
              badgeCount: selected == StaffIncidentsTab.myIncidents ? null : totalCount,
              onTap: () => onSelected(StaffIncidentsTab.myIncidents),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: 'All Incidents',
              isActive: selected == StaffIncidentsTab.allIncidents,
              badgeCount: selected == StaffIncidentsTab.allIncidents ? null : totalCount,
              onTap: () => onSelected(StaffIncidentsTab.allIncidents),
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
