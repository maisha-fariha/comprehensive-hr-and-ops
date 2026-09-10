import 'package:flutter/foundation.dart';

/// A selectable assignee from `GET /staff/directory` (picker-safe staff list).
@immutable
class TaskStaffOption {
  final String id;
  final String name;
  final String? subtitle;

  const TaskStaffOption({
    required this.id,
    required this.name,
    this.subtitle,
  });
}
