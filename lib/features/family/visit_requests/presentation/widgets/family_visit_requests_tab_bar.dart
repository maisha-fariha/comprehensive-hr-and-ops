import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_visit_requests_enums.dart';

const Map<FamilyVisitRequestsTab, String> _tabLabels = {
  FamilyVisitRequestsTab.all: 'All',
  FamilyVisitRequestsTab.myRequests: 'My Requests',
  FamilyVisitRequestsTab.history: 'History',
};

/// Segmented All / My Requests / History control for Visit Requests.
class FamilyVisitRequestsTabBar extends StatelessWidget {
  final FamilyVisitRequestsTab selected;
  final ValueChanged<FamilyVisitRequestsTab> onSelected;

  static const Color _track = Color(0xFFF0F4F7);
  static const Color _activeText = Color(0xFF0B6B5F);
  static const Color _inactiveText = Color(0xFF8E9BAE);
  static const Color _shadow = Color(0xFF142846);

  const FamilyVisitRequestsTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 15);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          for (final tab in FamilyVisitRequestsTab.values)
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
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 11,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 8),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: FamilyVisitRequestsTabBar._shadow.withValues(
                      alpha: 0.08,
                    ),
                    offset: Offset(
                      0,
                      ResponsiveHelper.getResponsiveHeight(context, 1),
                    ),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
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
                ? FamilyVisitRequestsTabBar._activeText
                : FamilyVisitRequestsTabBar._inactiveText,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
