import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single row in the web "Given" tab
/// (`GET /mar/administrations`).
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
  final String outcomeLabel;
  final String residenceName;

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
    this.outcomeLabel = 'Given',
    this.residenceName = '',
  });
}
