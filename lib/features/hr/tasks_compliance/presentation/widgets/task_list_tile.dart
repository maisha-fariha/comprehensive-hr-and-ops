import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/tasks_compliance_enums.dart';

class _StatusStyle {
  final Color color;
  final Color background;
  final String label;

  const _StatusStyle({
    required this.color,
    required this.background,
    required this.label,
  });
}

const Map<TaskStatus, _StatusStyle> _statusStyles = {
  TaskStatus.overdue: _StatusStyle(
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    label: 'Overdue',
  ),
  TaskStatus.due: _StatusStyle(
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    label: 'Pending',
  ),
  TaskStatus.upcoming: _StatusStyle(
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    label: 'Pending',
  ),
  TaskStatus.completed: _StatusStyle(
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
    label: 'Completed',
  ),
};

class _PriorityStyle {
  final Color color;
  final Color background;

  const _PriorityStyle({required this.color, required this.background});
}

_PriorityStyle _priorityStyle(String label) {
  switch (label.toLowerCase()) {
    case 'high':
    case 'urgent':
      return const _PriorityStyle(
        color: Color(0xFFD64545),
        background: Color(0xFFFBEDED),
      );
    case 'low':
      return const _PriorityStyle(
        color: Color(0xFF64748B),
        background: Color(0xFFF1F5F9),
      );
    default:
      return const _PriorityStyle(
        color: Color(0xFFB36B21),
        background: Color(0xFFFCF5ED),
      );
  }
}

/// Task Management list row — staff / residence / type / priority / progress.
class TaskListTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTap;

  const TaskListTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusStyle = task.awaitingReview
        ? const _StatusStyle(
            color: Color(0xFF0284C7),
            background: Color(0xFFE0F2FE),
            label: 'Awaiting review',
          )
        : _statusStyles[task.status]!;
    final priority = _priorityStyle(task.priorityLabel);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final progressLabel = task.checklistTotal > 0
        ? '${task.checklistDone}/${task.checklistTotal}'
        : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            14,
                          ),
                          color: AppColors.textHeading,
                          height: 1.25,
                        ),
                      ),
                      if (task.clientName.trim().isNotEmpty) ...[
                        SizedBox(
                          height:
                              ResponsiveHelper.getResponsiveHeight(context, 2),
                        ),
                        Text(
                          task.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12,
                            ),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusStyle.label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: statusStyle.color,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (task.assigneeName.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: Text(
                          task.assigneeInitials.isEmpty
                              ? '?'
                              : task.assigneeInitials,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.extraAssigneeCount > 0
                            ? '${task.assigneeName} +${task.extraAssigneeCount}'
                            : task.assigneeName,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                if (task.residenceName.isNotEmpty)
                  _MetaChip(icon: Icons.home_outlined, text: task.residenceName),
                if (task.typeLabel.isNotEmpty)
                  _MetaChip(icon: Icons.category_outlined, text: task.typeLabel),
                if (task.priorityLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priority.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      task.priorityLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          11,
                        ),
                        color: priority.color,
                      ),
                    ),
                  ),
                if (task.timeLabel.isNotEmpty)
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    text: task.timeLabel,
                  ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: task.progressFraction,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE8EEF2),
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ),
                if (progressLabel != null) ...[
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveWidth(context, 8),
                  ),
                  Text(
                    progressLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.getResponsiveWidth(context, 160),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textBody,
            ),
          ),
        ),
      ],
    );
  }
}
