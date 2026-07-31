import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single card in the "Refused" tab's "Refused by Client" list.
@immutable
class RefusedDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final MedicationRoute route;
  final String timeLabel;
  final String refusedByName;
  final String notes;

  const RefusedDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.route,
    required this.timeLabel,
    required this.refusedByName,
    required this.notes,
  });
}
