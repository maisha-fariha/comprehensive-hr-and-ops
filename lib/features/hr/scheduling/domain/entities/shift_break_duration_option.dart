import 'package:flutter/foundation.dart';

/// A selectable break duration for Create Shift.
@immutable
class ShiftBreakDurationOption {
  final String id;
  final String label;
  final int minutes;

  const ShiftBreakDurationOption({
    required this.id,
    required this.label,
    required this.minutes,
  });

  /// Fixed options from the Create Shift design reference.
  static const List<ShiftBreakDurationOption> predefined = [
    ShiftBreakDurationOption(id: 'none', label: 'None', minutes: 0),
    ShiftBreakDurationOption(id: '15', label: '15 minutes', minutes: 15),
    ShiftBreakDurationOption(id: '30', label: '30 minutes', minutes: 30),
    ShiftBreakDurationOption(id: '45', label: '45 minutes', minutes: 45),
    ShiftBreakDurationOption(id: '60', label: '60 minutes', minutes: 60),
  ];

  static const ShiftBreakDurationOption defaultOption = ShiftBreakDurationOption(
    id: '30',
    label: '30 minutes',
    minutes: 30,
  );
}
