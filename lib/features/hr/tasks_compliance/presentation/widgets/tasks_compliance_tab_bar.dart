import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

const Map<TasksComplianceTab, String> _tabLabels = {
  TasksComplianceTab.tasks: 'Tasks',
  TasksComplianceTab.compliance: 'Compliance',
  TasksComplianceTab.corrective: 'Corrective',
};

/// Pill segmented control: Tasks | Compliance | Corrective.
/// Selected segment = raised white pill with teal label.
class TasksComplianceTabBar extends StatelessWidget {
  final TasksComplianceTab selectedTab;
  final ValueChanged<TasksComplianceTab> onTabSelected;
  final int complianceAlertCount;

  static const Color _trackBackground = Color(0xFFF1F5F9);
  static const Color _selectedLabel = Color(0xFF0D685E);
  static const Color _unselectedLabel = Color(0xFF718096);
  static const Color _alertBadge = Color(0xFFD64545);

  const TasksComplianceTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.complianceAlertCount = 0,
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
          for (final tab in TasksComplianceTab.values)
            Expanded(
              child: _TabSegment(
                label: _tabLabels[tab]!,
                isSelected: tab == selectedTab,
                badgeCount: tab == TasksComplianceTab.compliance
                    ? complianceAlertCount
                    : 0,
                onTap: () => onTabSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _TabSegment({
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
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
                    offset: Offset(
                      0,
                      ResponsiveHelper.getResponsiveHeight(context, 1),
                    ),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 3),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: isSelected
                      ? TasksComplianceTabBar._selectedLabel
                      : TasksComplianceTabBar._unselectedLabel,
                  height: 1.1,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Container(
                constraints: BoxConstraints(
                  minWidth: ResponsiveHelper.getResponsiveSize(context, 16),
                  minHeight: ResponsiveHelper.getResponsiveSize(context, 16),
                ),
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 4,
                ),
                decoration: const BoxDecoration(
                  color: TasksComplianceTabBar._alertBadge,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 9),
                    color: Colors.white,
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
