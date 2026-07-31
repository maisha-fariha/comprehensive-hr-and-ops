import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_visit_requests_enums.dart';

/// Segmented "All / My Requests / History" tab control at the top of the
/// Visit Requests list screen - the active segment renders as a white pill
/// inside a light-grey track, matching the exact visual style already used
/// by e.g. `StaffIncidentsTabBar`/`StaffMedicationTabBar`.
class FamilyVisitRequestsTabBar extends StatelessWidget {
  final FamilyVisitRequestsTab selected;
  final ValueChanged<FamilyVisitRequestsTab> onSelected;

  const FamilyVisitRequestsTabBar({
    super.key,
    required this.selected,
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
          for (final tab in FamilyVisitRequestsTab.values)
            Expanded(
              child: _TabItem(
                label: _labelFor(tab),
                isActive: selected == tab,
                onTap: () => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(FamilyVisitRequestsTab tab) {
    switch (tab) {
      case FamilyVisitRequestsTab.all:
        return 'All';
      case FamilyVisitRequestsTab.myRequests:
        return 'My Requests';
      case FamilyVisitRequestsTab.history:
        return 'History';
    }
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.isActive, required this.onTap});

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
        child: Text(
          label,
          textAlign: TextAlign.center,
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
    );
  }
}
