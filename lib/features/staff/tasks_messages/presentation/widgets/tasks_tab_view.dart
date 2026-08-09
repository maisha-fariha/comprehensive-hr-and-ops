import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import 'quick_links_section.dart';
import 'task_filter_chips.dart';
import 'task_row_tile.dart';

/// Body of the "Tasks" tab: title, filter chips, and a single card list.
class TasksTabView extends StatelessWidget {
  final List<StaffTask> tasks;
  final TaskFilter selectedFilter;
  final int Function(TaskFilter filter) countFor;
  final ValueChanged<TaskFilter> onFilterSelected;
  final ValueChanged<StaffTask>? onTaskTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _divider = Color(0xFFEEF2F6);

  const TasksTabView({
    super.key,
    required this.tasks,
    required this.selectedFilter,
    required this.countFor,
    required this.onFilterSelected,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardRadius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            color: _titleColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        TaskFilterChips(
          selected: selectedFilter,
          countFor: countFor,
          onSelected: onFilterSelected,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        if (tasks.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowNavy.withValues(alpha: 0.04),
                  offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
                  blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: _divider),
                  TaskRowTile(
                    task: tasks[i],
                    onTap: onTaskTap == null ? null : () => onTaskTap!(tasks[i]),
                  ),
                ],
              ],
            ),
          ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        const QuickLinksSection(),
      ],
    );
  }
}
