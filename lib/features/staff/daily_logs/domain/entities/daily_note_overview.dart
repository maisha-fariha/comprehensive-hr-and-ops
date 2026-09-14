import 'package:flutter/foundation.dart';

import 'daily_note_attachment.dart';
import 'daily_note_field.dart';

/// Aggregate root for the "Daily Note" screen's fetched content.
@immutable
class DailyNoteOverview {
  final List<DailyNoteField> fields;
  final String body;
  final String? entryId;

  /// `draft` | `submitted` | empty for a new note.
  final String status;

  /// `morning` | `afternoon` | `night` | `day`.
  final String shift;

  /// Whether a wellness check was performed (separate from the grade).
  final bool wellnessCheckCompleted;

  /// Bring this note to a manager's attention on submit.
  final bool flagForAttention;

  final List<DailyNoteAttachment> attachments;

  const DailyNoteOverview({
    required this.fields,
    this.body = '',
    this.entryId,
    this.status = '',
    this.shift = '',
    this.wellnessCheckCompleted = false,
    this.flagForAttention = false,
    this.attachments = const [],
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isSubmitted => status.toLowerCase() == 'submitted';

  DailyNoteOverview copyWith({
    List<DailyNoteField>? fields,
    String? body,
    String? entryId,
    String? status,
    String? shift,
    bool? wellnessCheckCompleted,
    bool? flagForAttention,
    List<DailyNoteAttachment>? attachments,
  }) {
    return DailyNoteOverview(
      fields: fields ?? this.fields,
      body: body ?? this.body,
      entryId: entryId ?? this.entryId,
      status: status ?? this.status,
      shift: shift ?? this.shift,
      wellnessCheckCompleted:
          wellnessCheckCompleted ?? this.wellnessCheckCompleted,
      flagForAttention: flagForAttention ?? this.flagForAttention,
      attachments: attachments ?? this.attachments,
    );
  }
}
