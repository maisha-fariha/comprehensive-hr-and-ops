import 'package:flutter/foundation.dart';

@immutable
class TaskCreationOption {
  final String id;
  final String label;
  final String subtitle;

  const TaskCreationOption({
    required this.id,
    required this.label,
    this.subtitle = '',
  });
}

@immutable
class TaskCreationOptions {
  final List<TaskCreationOption> shifts;
  final List<TaskCreationOption> residences;
  final List<TaskCreationOption> staff;
  final String? defaultResidenceId;
  final String? defaultStaffId;

  const TaskCreationOptions({
    this.shifts = const [],
    this.residences = const [],
    this.staff = const [],
    this.defaultResidenceId,
    this.defaultStaffId,
  });
}
