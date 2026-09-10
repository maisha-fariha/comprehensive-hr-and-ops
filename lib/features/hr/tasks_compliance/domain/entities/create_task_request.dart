import 'package:flutter/foundation.dart';

/// Payload for `POST /tasks` (and optionally `POST /tasks/recurring`).
@immutable
class CreateTaskRequest {
  final String residenceId;
  final String title;
  final String? roomArea;
  final String? clientId;
  final String? description;
  final String taskType;
  final String priority;
  final DateTime? dueAt;
  final bool requiresReview;
  final bool recurring;
  final List<String> assignedStaffIds;
  final List<CreateTaskChecklistItem> checklist;
  final String? notes;

  const CreateTaskRequest({
    required this.residenceId,
    required this.title,
    this.roomArea,
    this.clientId,
    this.description,
    required this.taskType,
    required this.priority,
    this.dueAt,
    this.requiresReview = false,
    this.recurring = false,
    this.assignedStaffIds = const [],
    this.checklist = const [],
    this.notes,
  });
}

@immutable
class CreateTaskChecklistItem {
  final String label;
  final bool required;

  const CreateTaskChecklistItem({
    required this.label,
    this.required = false,
  });
}
