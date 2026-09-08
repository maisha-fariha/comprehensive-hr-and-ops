import 'package:flutter/foundation.dart';

/// A selectable shift type for Create Shift.
@immutable
class ShiftTypeOption {
  final String id;
  final String label;
  final String name;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;

  const ShiftTypeOption({
    required this.id,
    required this.label,
    required this.name,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  });

  bool get hasPresetTimes =>
      startHour != null &&
      startMinute != null &&
      endHour != null &&
      endMinute != null;

  /// Fixed options from the Create Shift design reference.
  static const List<ShiftTypeOption> predefined = [
    ShiftTypeOption(
      id: 'morning',
      name: 'Morning',
      label: 'Morning (07:00 – 15:00)',
      startHour: 7,
      startMinute: 0,
      endHour: 15,
      endMinute: 0,
    ),
    ShiftTypeOption(
      id: 'afternoon',
      name: 'Afternoon',
      label: 'Afternoon (15:00 – 23:00)',
      startHour: 15,
      startMinute: 0,
      endHour: 23,
      endMinute: 0,
    ),
    ShiftTypeOption(
      id: 'night',
      name: 'Night',
      label: 'Night (23:00 – 07:00)',
      startHour: 23,
      startMinute: 0,
      endHour: 7,
      endMinute: 0,
    ),
    ShiftTypeOption(
      id: 'day',
      name: 'Day',
      label: 'Day (08:00 – 16:00)',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
    ),
    ShiftTypeOption(
      id: 'custom',
      name: 'Custom',
      label: 'Custom',
    ),
  ];
}
