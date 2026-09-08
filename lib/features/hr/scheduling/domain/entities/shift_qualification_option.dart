import 'package:flutter/foundation.dart';

/// A selectable required qualification for Create Shift.
@immutable
class ShiftQualificationOption {
  final String id;
  final String label;

  const ShiftQualificationOption({
    required this.id,
    required this.label,
  });

  /// Fixed options from the Create Shift design reference.
  static const List<ShiftQualificationOption> predefined = [
    ShiftQualificationOption(
      id: 'behavioral-support-specialist',
      label: 'Behavioral Support Specialist',
    ),
    ShiftQualificationOption(
      id: 'child-and-youth-caregiver',
      label: 'Child and Youth Caregiver',
    ),
    ShiftQualificationOption(
      id: 'night-awake-staff',
      label: 'Night Awake Staff',
    ),
    ShiftQualificationOption(
      id: 'personal-support-worker',
      label: 'Personal Support Worker',
    ),
    ShiftQualificationOption(
      id: 'residential-support-worker',
      label: 'Residential Support Worker',
    ),
  ];
}
