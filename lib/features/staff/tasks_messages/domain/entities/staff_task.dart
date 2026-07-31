import 'package:flutter/foundation.dart';

import 'tasks_messages_enums.dart';

/// A single row in the "Tasks" tab's task list.
@immutable
class StaffTask {
  final String id;
  final String title;

  /// e.g. "8:00 AM" - rendered as "Due: 8:00 AM".
  final String dueTimeLabel;

  /// e.g. "Sunrise Home".
  final String location;
  final TaskStatus status;

  const StaffTask({
    required this.id,
    required this.title,
    required this.dueTimeLabel,
    required this.location,
    required this.status,
  });
}
