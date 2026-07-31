import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

const Map<TasksComplianceTab, String> _tabLabels = {
  TasksComplianceTab.tasks: 'Tasks',
  TasksComplianceTab.compliance: 'Compliance',
  TasksComplianceTab.corrective: 'Corrective',
};

/// The segmented "Tasks | Compliance | Corrective" control shared by all 3
/// tabs of the "Tasks & Compliance" screen.
class TasksComplianceTabBar extends StatelessWidget {
  final TasksComplianceTab selectedTab;
  final ValueChanged<TasksComplianceTab> onTabSelected;

  const TasksComplianceTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
      ),
      child: Row(
        children: TasksComplianceTab.values.map((tab) {
          final isSelected = tab == selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: ResponsiveHelper.getResponsivePadding(context, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 11)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.shadowNavy.withValues(alpha: 0.06),
                            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabels[tab]!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: isSelected ? AppColors.secondaryTeal : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
