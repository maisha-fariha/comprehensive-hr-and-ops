import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single card in the "Administered" tab's "Administered Today" list.
@immutable
class AdministeredDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final MedicationRoute route;
  final String givenTimeLabel;
  final String administeredByName;

  const AdministeredDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.route,
    required this.givenTimeLabel,
    required this.administeredByName,
  });
}
