import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single card in the "Missed" tab's "Missed Doses" list.
@immutable
class MissedDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final MedicationRoute route;
  final String scheduledTimeLabel;
  final String missedByName;
  final String reason;

  const MissedDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.route,
    required this.scheduledTimeLabel,
    required this.missedByName,
    required this.reason,
  });
}
