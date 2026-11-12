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
  final String? id;
  final String label;
  final bool done;

  /// Web “Must be done”: the task cannot be closed without this step.
  final bool required;

  /// Optional recorded value (e.g. temperature) shown beside the label on web.
  final String value;

  const StaffTaskCheckItem({
    this.id,
    required this.label,
    this.done = false,
    this.required = false,
    this.value = '',
  });

  StaffTaskCheckItem copyWith({bool? done}) {
    return StaffTaskCheckItem(
      id: id,
      label: label,
      done: done ?? this.done,
      required: required,
      value: value,
    );
  }

  /// Label as shown on web, including any recorded value.
  String get displayLabel {
    final v = value.trim();
    if (v.isEmpty) return label;
    if (label.contains(v)) return label;
    return '$label ($v)';
  }

  /// Body the web sends on Save progress and Submit for review.
  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        'label': label,
        'done': done,
        'required': required,
        if (value.trim().isNotEmpty) 'value': value.trim(),
      };
}

/// A file already attached to the task.
@immutable
class StaffTaskDocument {
  final String label;

  /// Stored file path, e.g. `/api/v1/files/{tenant}/tasks/{file}.pdf`.
  final String? url;

  const StaffTaskDocument({required this.label, this.url});
}

/// Detail from `GET /tasks/{id}` plus notes.
@immutable
class StaffTaskDetail {
  final String id;
  final String title;
  final String description;
  final String statusRaw;
  final String dueLabel;
  final DateTime? dueAt;
  final String location;
  final String clientName;
  final String assigneeName;
  final String priorityRaw;
  final String taskTypeRaw;
  final List<StaffTaskNote> notes;
  final List<StaffTaskCheckItem> checklist;
  final List<StaffTaskDocument> documents;

  /// The person completing it must confirm with their name (web sign-off).
  final bool requiresSignOff;
  final bool requiresReview;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? reviewedByIp;
  final DateTime? reviewedAt;
  final String reviewNotes;
  final String? signedOffBy;
  final String? signedOffName;
  final DateTime? signedOffAt;
  final String? signedOffIp;

  const StaffTaskDetail({
    required this.id,
    required this.title,
    this.description = '',
    this.statusRaw = '',
    this.dueLabel = '',
    this.dueAt,
    this.location = '',
    this.clientName = '',
    this.assigneeName = '',
    this.priorityRaw = '',
    this.taskTypeRaw = '',
    this.notes = const [],
    this.checklist = const [],
    this.documents = const [],
    this.requiresSignOff = false,
    this.requiresReview = false,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedByIp,
    this.reviewedAt,
    this.reviewNotes = '',
    this.signedOffBy,
    this.signedOffName,
    this.signedOffAt,
    this.signedOffIp,
  });

  bool get isCompleted {
    final s = statusRaw.toLowerCase();
    return s.contains('complete') || s == 'done';
  }

  /// Web review box: finished (or already in a review status), review required,
  /// and nobody has reviewed it yet.
  bool get awaitingReview {
    final raw = statusRaw.toLowerCase();
    if (reviewedAt != null) return false;
    if (raw == 'pending_review' ||
        raw == 'awaiting_review' ||
        raw == 'in_review' ||
        raw == 'review') {
      return true;
    }
    return isCompleted && requiresReview;
  }

  /// Web status pill. Past-due open tasks show Overdue (API may still say pending).
  String get statusLabel {
    if (awaitingReview) return 'Awaiting review';
    final raw = statusRaw.toLowerCase();
    if (raw.contains('complete') ||
        raw == 'done' ||
        raw == 'closed' ||
        raw == 'approved') {
      return 'Completed';
    }
    if (raw.contains('overdue') || raw == 'late') return 'Overdue';
    if (dueAt != null && dueAt!.toUtc().isBefore(DateTime.now().toUtc())) {
      return 'Overdue';
    }
    switch (raw) {
      case '':
      case 'open':
      case 'pending':
      case 'due':
        return 'Pending';
      case 'in_progress':
        return 'In progress';
      default:
        return _words(statusRaw);
    }
  }

  /// Web Task Details → Review.
  String get reviewTitle {
    if (!requiresReview) return 'Not required';
    final name = reviewedByName?.trim() ?? '';
    if (reviewedAt != null) {
      return name.isNotEmpty ? 'Reviewed by $name' : 'Reviewed';
    }
    if (awaitingReview) return 'Waiting on a reviewer';
    return 'Required';
  }

  String? get reviewNote {
    final note = reviewNotes.trim();
    return note.isEmpty ? null : note;
  }

  /// IP recorded with manager review sign-off.
  String? get reviewIpLabel {
    final ip = reviewedByIp?.trim() ?? '';
    return ip.isEmpty ? null : 'IP $ip';
  }

  /// Web Task Details → Sign-Off (“Needed to complete” when still open).
  String get signOffTitle {
    if (!requiresSignOff) return 'Not required';
    final name = signedOffName?.trim() ?? '';
    if (name.isNotEmpty) return 'Signed off by $name';
    if (signedOffAt != null) return 'Signed off';
    return 'Needed to complete';
  }

  /// IP recorded with staff execution sign-off (shown under the timestamp).
  String? get signOffIpLabel {
    final ip = signedOffIp?.trim() ?? '';
    return ip.isEmpty ? null : 'IP $ip';
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
