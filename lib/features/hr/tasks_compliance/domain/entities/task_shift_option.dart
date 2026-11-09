import 'package:flutter/foundation.dart';

/// A shift the new task can belong to (`GET /shifts?residenceId=`), labelled
/// the way the web describes shifts.
@immutable
class TaskShiftOption {
  final String id;
  final String label;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Web prefixes the in-progress shift with `[Active]` and lists it first.
  final bool isActive;

  const TaskShiftOption({
    required this.id,
    required this.label,
    this.startsAt,
    this.endsAt,
    this.isActive = false,
  });
}
