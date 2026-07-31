import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/staff_task.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import 'task_filter_chips.dart';
import 'task_row_tile.dart';

/// Body content of the "Tasks" tab: the filter chip row, the filtered task
/// list, and the (intentionally header-only) "Quick Links" section that
/// starts below it.
class TasksTabView extends StatelessWidget {
  final List<StaffTask> tasks;
  final TaskFilter selectedFilter;
  final int Function(TaskFilter filter) countFor;
  final ValueChanged<TaskFilter> onFilterSelected;
  final ValueChanged<StaffTask>? onTaskTap;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderRow(title: 'Tasks'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        TaskFilterChips(
          selected: selectedFilter,
          countFor: countFor,
          onSelected: onFilterSelected,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        for (final task in tasks) ...[
          TaskRowTile(task: task, onTap: onTaskTap == null ? null : () => onTaskTap!(task)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        // The reference screenshot cuts off right below this heading, so no
        // content is rendered underneath it - only the section header
        // itself is reproduced.
        const SectionHeaderRow(title: 'Quick Links'),
      ],
    );
  }
}
