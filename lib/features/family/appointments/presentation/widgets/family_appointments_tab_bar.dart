import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_appointments_enums.dart';

const Map<FamilyAppointmentsTab, String> _tabLabels = {
  FamilyAppointmentsTab.all: 'All',
  FamilyAppointmentsTab.upcoming: 'Upcoming',
  FamilyAppointmentsTab.completed: 'Completed',
};

/// Segmented All / Upcoming / Completed control for Appointments.
class FamilyAppointmentsTabBar extends StatelessWidget {
  final FamilyAppointmentsTab selected;
  final ValueChanged<FamilyAppointmentsTab> onSelected;

  static const Color _track = Color(0xFFF4F7F9);
  static const Color _activeText = Color(0xFF0E7C7B);
  static const Color _inactiveText = Color(0xFF8E9BAE);
  static const Color _shadow = Color(0xFF142846);

  const FamilyAppointmentsTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 15),
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

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: FamilyAppointmentsTabBar._shadow.withValues(alpha: 0.06),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: isActive
                ? FamilyAppointmentsTabBar._activeText
                : FamilyAppointmentsTabBar._inactiveText,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
