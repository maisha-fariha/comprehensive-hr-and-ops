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

/// Detail from `GET /tasks/{id}` plus notes.
@immutable
class StaffTaskDetail {
  final String id;
  final String title;
  final String description;
  final String statusRaw;
  final String dueLabel;
  final String location;
  final List<StaffTaskNote> notes;

  const StaffTaskDetail({
    required this.id,
    required this.title,
    this.description = '',
    this.statusRaw = '',
    this.dueLabel = '',
    this.location = '',
    this.notes = const [],
  });

  bool get isCompleted {
    final s = statusRaw.toLowerCase();
    return s.contains('complete') || s == 'done';
  }
}
