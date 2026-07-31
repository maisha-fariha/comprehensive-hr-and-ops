import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single row in the "Tasks Due" list on the "Tasks" tab.
@immutable
class TaskItem {
  final String id;
  final String title;
  final TaskCategory category;
  final String timeLabel;

  /// Whether [timeLabel] represents a same-day time (e.g. "Today, 10:00 AM",
  /// rendered with a clock caption icon) rather than a future date (e.g.
  /// "May 15, 9:00 AM", rendered with a calendar caption icon).
  final bool isToday;
  final TaskStatus status;

  const TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timeLabel,
    required this.isToday,
    required this.status,
  });
}
