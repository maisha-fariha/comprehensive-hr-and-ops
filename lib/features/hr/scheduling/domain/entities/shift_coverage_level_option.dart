import 'package:flutter/foundation.dart';

/// A selectable coverage level for Create Shift.
@immutable
class ShiftCoverageLevelOption {
  final String id;
  final String label;

  const ShiftCoverageLevelOption({
    required this.id,
    required this.label,
  });

  /// Fixed options from the Create Shift design reference.
  static const List<ShiftCoverageLevelOption> predefined = [
    ShiftCoverageLevelOption(id: 'standard', label: 'Standard'),
    ShiftCoverageLevelOption(id: 'enhanced', label: 'Enhanced'),
    ShiftCoverageLevelOption(id: 'critical', label: 'Critical'),
  ];

  static const ShiftCoverageLevelOption defaultOption = ShiftCoverageLevelOption(
    id: 'standard',
    label: 'Standard',
  );
}
