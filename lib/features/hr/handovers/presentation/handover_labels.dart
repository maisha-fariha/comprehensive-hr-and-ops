import '../../attendance/presentation/widgets/attendance_record_card.dart';

/// Labels and pill tones from the web handovers page.
abstract final class HandoverLabels {
  static const statuses = [
    ('draft', 'Draft'),
    ('submitted', 'Submitted'),
    ('viewed', 'Read'),
    ('acknowledged', 'Acknowledged'),
  ];

  static String status(String value) =>
      statuses.firstWhere((s) => s.$1 == value, orElse: () => (value, value)).$2;

  static AttendanceTone statusTone(String value) => switch (value) {
        'submitted' || 'viewed' => AttendanceTone.info,
        'acknowledged' => AttendanceTone.success,
        _ => AttendanceTone.neutral,
      };

  static const clientStatuses = [
    ('stable', 'Stable'),
    ('needs_attention', 'Needs attention'),
    ('urgent', 'Urgent'),
  ];

  static String clientStatus(String value) => clientStatuses
      .firstWhere((s) => s.$1 == value, orElse: () => (value, value))
      .$2;

  static AttendanceTone clientTone(String value) => switch (value) {
        'needs_attention' => AttendanceTone.warning,
        'urgent' => AttendanceTone.danger,
        _ => AttendanceTone.success,
      };

  static const careTasks = [
    ('personal_care', 'Personal care'),
    ('feeding', 'Feeding'),
    ('mobility_assistance', 'Mobility assistance'),
    ('hygiene', 'Hygiene'),
  ];

  static String careTask(String value) =>
      careTasks.firstWhere((s) => s.$1 == value, orElse: () => (value, value)).$2;

  /// Priorities typed on the record form.
  static const jobPriorities = [
    ('normal', 'Normal'),
    ('important', 'Important'),
    ('urgent', 'Urgent'),
  ];

  static AttendanceTone jobTone(String value) => switch (value) {
        'important' => AttendanceTone.warning,
        'urgent' => AttendanceTone.danger,
        _ => AttendanceTone.info,
      };

  /// Task priorities the server stores for those jobs.
  static String taskPriority(String value) => switch (value) {
        'medium' => 'Normal',
        'high' => 'Important',
        'urgent' => 'Urgent',
        _ => value,
      };

  static AttendanceTone taskPriorityTone(String value) => switch (value) {
        'high' => AttendanceTone.warning,
        'urgent' => AttendanceTone.danger,
        _ => AttendanceTone.info,
      };

  static const flagCategories = [
    ('behaviour', 'Behaviour'),
    ('medical', 'Medical'),
    ('safeguarding', 'Safeguarding'),
    ('medication', 'Medication'),
    ('environment', 'Environment'),
    ('other', 'Other'),
  ];

  /// `generalCondition` → `General condition`.
  static String fieldKey(String key) {
    final spaced = key
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m[1]}')
        .toLowerCase();
    return spaced.isEmpty ? spaced : spaced[0].toUpperCase() + spaced.substring(1);
  }
}
