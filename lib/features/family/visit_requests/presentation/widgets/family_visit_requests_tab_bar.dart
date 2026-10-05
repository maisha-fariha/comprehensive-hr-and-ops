import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/family_visit_requests_enums.dart';

const Map<FamilyVisitRequestsTab, String> _tabLabels = {
  FamilyVisitRequestsTab.all: 'All',
  FamilyVisitRequestsTab.pending: 'Pending',
  FamilyVisitRequestsTab.approved: 'Approved',
  FamilyVisitRequestsTab.rejected: 'Rejected',
  FamilyVisitRequestsTab.cancelled: 'Cancelled',
  FamilyVisitRequestsTab.completed: 'Completed',
};

const Map<FamilyVisitRequestsTab, Color> _tabColors = {
  FamilyVisitRequestsTab.all: Color(0xFF0B6B5F),
  FamilyVisitRequestsTab.pending: Color(0xFFE9A23B),
  FamilyVisitRequestsTab.approved: Color(0xFF3FA66D),
  FamilyVisitRequestsTab.rejected: Color(0xFFD64545),
  FamilyVisitRequestsTab.cancelled: Color(0xFF5A6B80),
  FamilyVisitRequestsTab.completed: Color(0xFF61758D),
};

/// Scrollable status tabs with counts; tapping one lists exactly the
/// requests with that status.
class FamilyVisitRequestsTabBar extends StatelessWidget {
  final FamilyVisitRequestsTab selected;
  final int Function(FamilyVisitRequestsTab tab) countFor;
  final ValueChanged<FamilyVisitRequestsTab> onSelected;

  static const Color _border = Color(0xFFEEF1F4);
  static const Color _label = Color(0xFF8E9BAE);
  static const Color _activeBorder = Color(0xFF8DC4BF);
  static const Color _activeFill = Color(0xFFF3FAF9);

  const FamilyVisitRequestsTabBar({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in FamilyVisitRequestsTab.values) ...[
            if (tab != FamilyVisitRequestsTab.values.first)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _StatusTab(
              key: ValueKey('visit-requests-tab-${tab.name}'),
              label: _tabLabels[tab]!,
              count: countFor(tab),
              color: _tabColors[tab]!,
              isActive: selected == tab,
              onTap: () => onSelected(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusTab({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(
            minWidth: ResponsiveHelper.getResponsiveWidth(context, 78),
          ),
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 10,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: isActive ? FamilyVisitRequestsTabBar._activeFill : Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 14),
            ),
            border: Border.all(
              color: isActive
                  ? FamilyVisitRequestsTabBar._activeBorder
                  : FamilyVisitRequestsTabBar._border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  color: color,
                  height: 1.1,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: isActive ? const Color(0xFF0B6B5F) : FamilyVisitRequestsTabBar._label,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
