import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single row in the Task Management list.
@immutable
class TaskItem {
  final String id;
  final String title;
  final TaskCategory category;
  final String timeLabel;

  /// Whether [timeLabel] represents a same-day time (e.g. "Today, 10:00 AM",
  /// rendered with a clock caption icon) rather than a future date.
  final bool isToday;
  final TaskStatus status;

  /// Finished, review required, and not reviewed yet. The list pill says
  /// “Awaiting review” instead of “Completed”.
  final bool awaitingReview;

  final String typeLabel;
  final String priorityLabel;
  final String assigneeName;
  final String assigneeInitials;
  final int extraAssigneeCount;
  final String residenceName;
  final String clientName;
  final int checklistDone;
  final int checklistTotal;

  const TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timeLabel,
    required this.isToday,
    required this.status,
    this.awaitingReview = false,
    this.typeLabel = '',
    this.priorityLabel = '',
    this.assigneeName = '',
    this.assigneeInitials = '',
    this.extraAssigneeCount = 0,
    this.residenceName = '',
    this.clientName = '',
    this.checklistDone = 0,
    this.checklistTotal = 0,
  });

  double get progressFraction {
    if (checklistTotal <= 0) {
      if (status == TaskStatus.completed && !awaitingReview) return 1;
      if (awaitingReview) return 0.9;
      return 0;
    }
    return (checklistDone / checklistTotal).clamp(0.0, 1.0);
  }
}
