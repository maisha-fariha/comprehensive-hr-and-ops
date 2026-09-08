import 'package:flutter/foundation.dart';

/// A selectable reminder option for Create Shift notifications.
@immutable
class ShiftReminderOption {
  final String id;
  final String label;
  final int? hoursBefore;

  const ShiftReminderOption({
    required this.id,
    required this.label,
    this.hoursBefore,
  });

  int? get minutesBefore =>
      hoursBefore == null ? null : hoursBefore! * 60;

  /// Fixed options from the Create Shift design reference.
  static const List<ShiftReminderOption> predefined = [
    ShiftReminderOption(id: 'none', label: 'No reminder'),
    ShiftReminderOption(
      id: '1h',
      label: '1 hour before',
      hoursBefore: 1,
    ),
    ShiftReminderOption(
      id: '24h',
      label: '24 hours before',
      hoursBefore: 24,
    ),
    ShiftReminderOption(
      id: '48h',
      label: '48 hours before',
      hoursBefore: 48,
    ),
  ];

  static const ShiftReminderOption defaultOption = ShiftReminderOption(
    id: 'none',
    label: 'No reminder',
  );
}
