import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';

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
    color: Color(0xFFB91C1C),
    background: Color(0xFFFEE2E2),
    label: 'Overdue',
  ),
  TaskStatus.pending: _StatusStyle(
    color: Color(0xFFC27803),
    background: Color(0xFFFFF0D8),
    label: 'Pending',
  ),
  TaskStatus.done: _StatusStyle(
    color: Color(0xFF2D8A56),
    background: Color(0xFFE8F6EF),
    label: 'Done',
  ),
};

/// A single task row inside the Tasks list card.
class TaskRowTile extends StatelessWidget {
  final StaffTask task;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF94A3B8);
  static const Color _doneTitle = Color(0xFF94A3B8);
  static const Color _overdueTime = Color(0xFFDC2626);
  static const Color _pendingRing = Color(0xFFCBD5E1);

  const TaskRowTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[task.status]!;
    final isDone = task.status == TaskStatus.done;
    final isOverdue = task.status == TaskStatus.overdue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveHelper.getResponsiveHeight(context, 2),
                ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                        color: isDone ? _doneTitle : _titleColor,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: _doneTitle,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: isDone ? _doneTitle : _metaColor,
                          height: 1.25,
                        ),
                        children: [
                          const TextSpan(text: 'Due: '),
                          TextSpan(
                            text: task.dueTimeLabel,
                            style: TextStyle(
                              fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w400,
                              color: isOverdue
                                  ? _overdueTime
                                  : (isDone ? _doneTitle : _metaColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      style.label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                        color: style.color,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  Text(
                    task.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: _metaColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusIndicator extends StatelessWidget {
  final TaskStatus status;

  const _TaskStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 20);

    switch (status) {
      case TaskStatus.overdue:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDC2626),
              width: ResponsiveHelper.getResponsiveSize(context, 1.8),
            ),
          ),
        );
      case TaskStatus.pending:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: TaskRowTile._pendingRing,
              width: ResponsiveHelper.getResponsiveSize(context, 1.8),
            ),
          ),
        );
      case TaskStatus.done:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF2D8A56),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 13),
            color: Colors.white,
          ),
        );
    }
  }
}
