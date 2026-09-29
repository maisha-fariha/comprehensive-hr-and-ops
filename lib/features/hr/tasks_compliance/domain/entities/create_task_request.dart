import 'package:flutter/foundation.dart';

/// Payload for `POST /tasks`, or `POST /tasks/recurring` when [recurrence] is
/// set. [taskType] and [priority] are API values (`follow_up`, `medium`).
@immutable
class CreateTaskRequest {
  final String residenceId;
  final String title;
  final String? roomArea;
  final String? clientId;
  final String? shiftId;
  final String? description;
  final String taskType;
  final String priority;
  final DateTime? dueAt;
  final bool requiresReview;
  final List<String> assignedStaffIds;
  final List<CreateTaskChecklistItem> checklist;
  final String? notes;
  final List<CreateTaskAttachment> attachments;
  final TaskRecurrence? recurrence;

  const CreateTaskRequest({
    required this.residenceId,
    required this.title,
    this.roomArea,
    this.clientId,
    this.shiftId,
    this.description,
    required this.taskType,
    required this.priority,
    this.dueAt,
    this.requiresReview = false,
    this.assignedStaffIds = const [],
    this.checklist = const [],
    this.notes,
    this.attachments = const [],
    this.recurrence,
  });

  bool get recurring => recurrence != null;
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

/// A local file uploaded to `/uploads?category=tasks` after the task exists.
@immutable
class CreateTaskAttachment {
  final String path;
  final String name;

  const CreateTaskAttachment({required this.path, required this.name});
}

/// The web's "Recurring Task" block: daily / weekly / monthly at one time of
/// day, fixed or rotating assignees, optionally stopping on a date.
@immutable
class TaskRecurrence {
  final String frequency;
  final int timeOfDayMinutes;
  final List<int> weekdays;
  final int? dayOfMonth;
  final bool rotating;
  final DateTime? endsOn;

  const TaskRecurrence({
    required this.frequency,
    required this.timeOfDayMinutes,
    this.weekdays = const [],
    this.dayOfMonth,
    this.rotating = false,
    this.endsOn,
  });
}
