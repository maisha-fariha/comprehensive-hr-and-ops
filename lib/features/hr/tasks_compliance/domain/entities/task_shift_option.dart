import 'package:flutter/foundation.dart';

/// A shift the new task can belong to (`GET /shifts?residenceId=`), labelled
/// the way the web describes shifts.
@immutable
class TaskShiftOption {
  final String id;
  final String label;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// True while [startsAt]–[endsAt] contains now (for selection helpers).
  /// Create Task menus list newest start first; they do not reorder on this.
  final bool isActive;

  const TaskShiftOption({
    required this.id,
    required this.label,
    this.startsAt,
    this.endsAt,
    this.isActive = false,
  });
}
