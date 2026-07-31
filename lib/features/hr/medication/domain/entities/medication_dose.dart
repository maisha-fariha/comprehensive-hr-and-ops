import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single row in the Overview tab's "Due Today" list, e.g. "James D. —
/// Lisinopril 10mg — 8:00 AM — Due".
@immutable
class MedicationDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final String timeLabel;

  const MedicationDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.timeLabel,
  });
}
