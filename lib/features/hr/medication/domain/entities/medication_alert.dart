import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single row in the Overview tab's "Missed / Refused Alerts" card, e.g.
/// "Maria S. — Tylenol 500mg · 10:30 AM — Refused — Resident declined
/// medication".
@immutable
class MedicationAlert {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String timeLabel;
  final AlertKind kind;
  final String note;

  const MedicationAlert({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.timeLabel,
    required this.kind,
    required this.note,
  });
}
