import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../staff_tasks_messages_constants.dart';

class _StatusStyle {
  final Color color;
  final Color background;
  final String label;

  const _StatusStyle({required this.color, required this.background, required this.label});
}

const Map<TaskStatus, _StatusStyle> _statusStyles = {
  TaskStatus.overdue: _StatusStyle(
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'Overdue',
  ),
  TaskStatus.pending: _StatusStyle(
    color: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
    label: 'Pending',
  ),
  TaskStatus.done: _StatusStyle(
    color: AppColors.activeGreen,
    background: AppColors.activeBackground,
    label: 'Done',
  ),
};

/// A single row in the "Tasks" tab's task list: a leading status indicator,
/// title + "Due: ..." + location, and a trailing status pill.
class TaskRowTile extends StatelessWidget {
  final StaffTask task;
  final VoidCallback? onTap;

  const TaskRowTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[task.status]!;
    final isDone = task.status == TaskStatus.done;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
              child: _TaskStatusIndicator(status: task.status),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      color: isDone ? AppColors.textMuted : AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    'Due: ${task.dueTimeLabel}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    task.location,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            StatusBadge.pill(
              label: style.label,
              background: style.background,
              foreground: style.color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Leading status glyph: a filled red dot for overdue tasks, an outlined
/// ring for pending tasks, and a green checkmark-in-circle for done tasks.
class _TaskStatusIndicator extends StatelessWidget {
  final TaskStatus status;

  const _TaskStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.overdue:
        return Container(
          width: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.taskStatusDotSize),
          height: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.taskStatusDotSize),
          decoration: const BoxDecoration(color: AppColors.criticalRed, shape: BoxShape.circle),
        );
      case TaskStatus.pending:
        return Container(
          width: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.taskStatusDotSize),
          height: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.taskStatusDotSize),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: StaffTasksMessagesColors.pendingRingColor,
              width: ResponsiveHelper.getResponsiveSize(context, 1.6),
            ),
          ),
        );
      case TaskStatus.done:
        return AppSvgIcon(AppAssets.checkCircle, size: 18, color: AppColors.activeGreen);
    }
  }
}
