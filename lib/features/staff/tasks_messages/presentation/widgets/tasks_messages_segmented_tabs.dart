import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_messages_enums.dart';

/// The pill-shaped "Tasks | Messages" segmented control shared by both tabs
/// of the "Tasks & Messages" screen. Per the reference screenshots, only the
/// *inactive* segment shows its item count next to the label (e.g.
/// "Messages 3" while "Tasks" is active, or "Tasks 6" while "Messages" is
/// active) - the active segment's count is already surfaced by the content
/// below it, so repeating it here would be redundant.
class TasksMessagesSegmentedTabs extends StatelessWidget {
  final TasksMessagesTab selectedTab;
  final int tasksCount;
  final int messagesCount;
  final ValueChanged<TasksMessagesTab> onTabSelected;

  const TasksMessagesSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.tasksCount = 0,
    this.messagesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Tasks',
              isSelected: selectedTab == TasksMessagesTab.tasks,
              onTap: () => onTabSelected(TasksMessagesTab.tasks),
              badgeCount: selectedTab == TasksMessagesTab.tasks ? 0 : tasksCount,
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Messages',
              isSelected: selectedTab == TasksMessagesTab.messages,
              onTap: () => onTabSelected(TasksMessagesTab.messages),
              badgeCount: selectedTab == TasksMessagesTab.messages ? 0 : messagesCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 11),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.08),
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
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: isSelected ? AppColors.secondaryTeal : AppColors.textMuted,
                ),
              ),
            ),
            if (badgeCount > 0) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                '$badgeCount',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: isSelected ? AppColors.secondaryTeal : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
