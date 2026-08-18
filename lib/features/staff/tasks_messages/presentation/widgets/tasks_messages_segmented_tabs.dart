import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/tasks_messages_enums.dart';

/// Pill-shaped "Tasks | Messages" segmented control.
///
/// Inactive segment shows a circular count badge; the active segment is a
/// raised white pill with teal label.
class TasksMessagesSegmentedTabs extends StatelessWidget {
  final TasksMessagesTab selectedTab;
  final int tasksCount;
  final int messagesCount;
  final ValueChanged<TasksMessagesTab> onTabSelected;

  static const Color _track = Color(0xFFF1F4F8);
  static const Color _inactiveLabel = Color(0xFF8899A6);
  static const Color _activeLabel = Color(0xFF005F56);
  static const Color _badgeBg = Color(0xFFE8F0FE);
  static const Color _badgeFg = Color(0xFF1A2B48);

  const TasksMessagesSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.tasksCount = 0,
    this.messagesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final trackRadius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final segmentRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Tasks',
              isSelected: selectedTab == TasksMessagesTab.tasks,
              radius: segmentRadius,
              badgeCount: selectedTab == TasksMessagesTab.tasks ? null : tasksCount,
              onTap: () => onTabSelected(TasksMessagesTab.tasks),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Messages',
              isSelected: selectedTab == TasksMessagesTab.messages,
              radius: segmentRadius,
              badgeCount: selectedTab == TasksMessagesTab.messages ? null : messagesCount,
              onTap: () => onTabSelected(TasksMessagesTab.messages),
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
  final double radius;
  final int? badgeCount;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.radius,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = !isSelected && badgeCount != null && badgeCount! > 0;
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 20);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          vertical: 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.08),
                    offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
                    blurRadius: ResponsiveHelper.getResponsiveHeight(context, 4),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: isSelected
                      ? TasksMessagesSegmentedTabs._activeLabel
                      : TasksMessagesSegmentedTabs._inactiveLabel,
                  height: 1.2,
                ),
              ),
            ),
            if (showBadge) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Container(
                constraints: BoxConstraints(minWidth: badgeSize, minHeight: badgeSize),
                height: badgeSize,
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
                decoration: const BoxDecoration(
                  color: TasksMessagesSegmentedTabs._badgeBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${badgeCount!}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: TasksMessagesSegmentedTabs._badgeFg,
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
