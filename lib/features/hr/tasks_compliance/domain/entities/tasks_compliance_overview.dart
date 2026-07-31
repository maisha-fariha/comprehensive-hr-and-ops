import 'package:flutter/foundation.dart';

import 'compliance_checklist_item.dart';
import 'compliance_stat.dart';
import 'compliance_summary.dart';
import 'corrective_action.dart';
import 'corrective_stat.dart';
import 'task_item.dart';
import 'task_stat.dart';

/// Aggregate root for everything shown on the "Tasks & Compliance" screen
/// (all 3 segmented tabs: Tasks, Compliance, Corrective).
@immutable
class TasksComplianceOverview {
  final String headerSubtitle;

  final List<TaskStat> taskStats;
  final int tasksDueCount;
  final List<TaskItem> taskItems;

  final ComplianceSummary complianceSummary;
  final List<ComplianceStat> complianceStats;
  final int complianceChecklistCount;
  final List<ComplianceChecklistItem> complianceChecklistItems;

  final List<CorrectiveStat> correctiveStats;
  final int correctiveActionsCount;
  final List<CorrectiveAction> correctiveActions;

  const TasksComplianceOverview({
    required this.headerSubtitle,
    required this.taskStats,
    required this.tasksDueCount,
    required this.taskItems,
    required this.complianceSummary,
    required this.complianceStats,
    required this.complianceChecklistCount,
    required this.complianceChecklistItems,
    required this.correctiveStats,
    required this.correctiveActionsCount,
    required this.correctiveActions,
  });
}
