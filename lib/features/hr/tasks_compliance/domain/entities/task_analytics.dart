import 'package:flutter/foundation.dart';

/// Charts row under the Task Management KPI cards (web parity).
@immutable
class TaskAnalytics {
  final int statusCompleted;
  final int statusPending;
  final int statusOverdue;
  final int? todayPercent;
  final int todayDue;
  final int todayCompleted;
  final int? trendChangePercent;
  final List<TaskTypeBreakdown> byType;
  final List<TaskTrendPoint> trend;

  const TaskAnalytics({
    required this.statusCompleted,
    required this.statusPending,
    required this.statusOverdue,
    required this.todayPercent,
    required this.todayDue,
    required this.todayCompleted,
    required this.trendChangePercent,
    required this.byType,
    required this.trend,
  });

  int get statusTotal => statusCompleted + statusPending + statusOverdue;

  double get overallCompletedFraction {
    if (statusTotal <= 0) return 0;
    return statusCompleted / statusTotal;
  }
}

@immutable
class TaskTypeBreakdown {
  final String type;
  final String label;
  final int total;
  final int completed;
  final int percent;

  const TaskTypeBreakdown({
    required this.type,
    required this.label,
    required this.total,
    required this.completed,
    required this.percent,
  });
}

@immutable
class TaskTrendPoint {
  final DateTime weekStart;
  final int completed;

  const TaskTrendPoint({
    required this.weekStart,
    required this.completed,
  });
}
