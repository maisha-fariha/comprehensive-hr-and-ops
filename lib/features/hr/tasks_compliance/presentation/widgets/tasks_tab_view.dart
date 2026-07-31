import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/tasks_compliance_overview.dart';
import 'section_count_badge.dart';
import 'task_list_tile.dart';
import 'task_stats_grid.dart';

/// Body content of the "Tasks" tab: the 2x2 stat grid + the "Tasks Due"
/// list.
class TasksTabView extends StatelessWidget {
  final TasksComplianceOverview overview;

  const TasksTabView({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskStatsGrid(stats: overview.taskStats),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Tasks Due',
          trailing: SectionCountBadge(count: overview.tasksDueCount),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (final task in overview.taskItems) ...[
          TaskListTile(task: task),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        ],
      ],
    );
  }
}
