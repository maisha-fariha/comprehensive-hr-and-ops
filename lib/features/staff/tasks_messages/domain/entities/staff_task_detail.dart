import 'package:flutter/foundation.dart';

/// One note on `GET /tasks/{id}/notes`.
@immutable
class StaffTaskNote {
  final String id;
  final String body;
  final String authorName;
  final String timeLabel;

  const StaffTaskNote({
    required this.id,
    required this.body,
    this.authorName = '',
    this.timeLabel = '',
  });
}

/// One checklist row on `GET /tasks/{id}`.
@immutable
class StaffTaskCheckItem {
  final String label;
  final bool done;

  const StaffTaskCheckItem({required this.label, this.done = false});
}

/// A file already attached to the task.
@immutable
class StaffTaskDocument {
  final String label;

  const StaffTaskDocument({required this.label});
}

/// Detail from `GET /tasks/{id}` plus notes.
@immutable
class StaffTaskDetail {
  final String id;
  final String title;
  final String description;
  final String statusRaw;
  final String dueLabel;
  final String location;
  final String assigneeName;
  final String priorityRaw;
  final String taskTypeRaw;
  final List<StaffTaskNote> notes;
  final List<StaffTaskCheckItem> checklist;
  final List<StaffTaskDocument> documents;

  /// The person completing it must confirm with their name (web sign-off).
  final bool requiresSignOff;
  final bool requiresReview;

  const StaffTaskDetail({
    required this.id,
    required this.title,
    this.description = '',
    this.statusRaw = '',
    this.dueLabel = '',
    this.location = '',
    this.assigneeName = '',
    this.priorityRaw = '',
    this.taskTypeRaw = '',
    this.notes = const [],
    this.checklist = const [],
    this.documents = const [],
    this.requiresSignOff = false,
    this.requiresReview = false,
  });

  bool get isCompleted {
    final s = statusRaw.toLowerCase();
    return s.contains('complete') || s == 'done';
  }

  /// Web status pill. An open task is shown as Pending.
  String get statusLabel {
    switch (statusRaw.toLowerCase()) {
      case '':
      case 'open':
      case 'pending':
      case 'due':
        return 'Pending';
      case 'in_progress':
        return 'In progress';
      case 'completed':
      case 'done':
      case 'complete':
      case 'closed':
        return 'Completed';
      case 'overdue':
      case 'late':
        return 'Overdue';
      default:
        return _words(statusRaw);
    }
  }

  String get typeLabel => _words(taskTypeRaw.replaceAll('_', ' '));

  String get priorityLabel {
    final word = _words(priorityRaw);
    return word.isEmpty ? '' : '$word priority';
  }

  /// "Other · Low priority" under the due time.
  String get kindLine => [
        typeLabel,
        priorityLabel,
      ].where((part) => part.isNotEmpty).join(' · ');

  int get checklistDone => checklist.where((item) => item.done).length;

  int get checklistPercent => checklist.isEmpty
      ? 0
      : ((checklistDone / checklist.length) * 100).round();

  static String _words(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    return text
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
