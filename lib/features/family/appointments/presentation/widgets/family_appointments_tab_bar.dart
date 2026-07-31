import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_appointments_enums.dart';

const Map<FamilyAppointmentsTab, String> _tabLabels = {
  FamilyAppointmentsTab.all: 'All',
  FamilyAppointmentsTab.upcoming: 'Upcoming',
  FamilyAppointmentsTab.completed: 'Completed',
};

/// Segmented "All / Upcoming / Completed" tab control at the top of the
/// Family Appointments list screen, reusing the raised-white-pill visual
/// pattern already established by `StaffIncidentsTabBar`/
/// `StaffMedicationTabBar` (rebuilt locally rather than imported, per the
/// Family portal's module boundary rules).
class FamilyAppointmentsTabBar extends StatelessWidget {
  final FamilyAppointmentsTab selected;
  final ValueChanged<FamilyAppointmentsTab> onSelected;

  const FamilyAppointmentsTabBar({super.key, required this.selected, required this.onSelected});

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
          for (final tab in FamilyAppointmentsTab.values)
            Expanded(
              child: _TabItem(
                label: _tabLabels[tab]!,
                isActive: selected == tab,
                onTap: () => onSelected(tab),
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
        alignment: Alignment.center,
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
    );
  }
}
