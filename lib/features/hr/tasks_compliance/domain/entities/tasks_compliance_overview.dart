import 'package:flutter/foundation.dart';

import 'compliance_checklist_item.dart';
import 'compliance_requirement_item.dart';
import 'compliance_stat.dart';
import 'compliance_summary.dart';
import 'corrective_action.dart';
import 'corrective_stat.dart';
import 'expiring_certificate.dart';
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
  final List<TaskItem> reviewQueueItems;
  final List<TaskItem> recurringItems;
  final List<ExpiringCertificate> expiringCertificates;

  final ComplianceSummary complianceSummary;
  final List<ComplianceStat> complianceStats;
  final int complianceChecklistCount;
  final List<ComplianceChecklistItem> complianceChecklistItems;
  final int upcomingReviewsCount;
  final List<ComplianceRequirementItem> upcomingReviews;
  final int complianceAlertCount;

  final List<CorrectiveStat> correctiveStats;
  final int correctiveActionsCount;
  final List<CorrectiveAction> correctiveActions;
  final int correctiveOverdueCount;
  final int recentResolutionsCount;
  final List<CorrectiveAction> recentResolutions;

  const TasksComplianceOverview({
    required this.headerSubtitle,
    required this.taskStats,
    required this.tasksDueCount,
    required this.taskItems,
    this.reviewQueueItems = const [],
    this.recurringItems = const [],
    this.expiringCertificates = const [],
    required this.complianceSummary,
    required this.complianceStats,
    required this.complianceChecklistCount,
    required this.complianceChecklistItems,
    this.upcomingReviewsCount = 0,
    this.upcomingReviews = const [],
    this.complianceAlertCount = 0,
    required this.correctiveStats,
    required this.correctiveActionsCount,
    required this.correctiveActions,
    this.correctiveOverdueCount = 0,
    this.recentResolutionsCount = 0,
    this.recentResolutions = const [],
  });
}
