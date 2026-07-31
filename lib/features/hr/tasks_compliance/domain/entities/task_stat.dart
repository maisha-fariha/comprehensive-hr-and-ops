import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single tile in the "Tasks" tab's 2x2 stat grid, e.g. "8 Due Today".
@immutable
class TaskStat {
  final String id;
  final TaskStatTag tag;
  final String value;
  final String label;

  const TaskStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
