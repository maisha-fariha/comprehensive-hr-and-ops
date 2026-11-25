import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single tile in the Task Management KPI row.
@immutable
class TaskStat {
  final String id;
  final TaskStatTag tag;
  final String value;
  final String label;

  /// Optional soft badge under/beside the value (e.g. "Nothing due", "Open").
  final String? badge;

  const TaskStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
    this.badge,
  });
}
