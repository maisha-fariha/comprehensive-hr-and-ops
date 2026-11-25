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

  /// Web "After its round".
  final bool wasLate;

  /// `false` → web red "Given off duty". Null when the API omits the flag.
  final bool? administeredOnDuty;

  /// `false` → web red "Witness off duty".
  final bool? witnessOnDuty;

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
    this.wasLate = false,
    this.administeredOnDuty,
    this.witnessOnDuty,
  });

  /// Web "Off duty only — doses to review".
  bool get isOffDutyReview =>
      administeredOnDuty == false || witnessOnDuty == false;

  AdministeredDose copyWith({
    String? residenceName,
  }) {
    return AdministeredDose(
      id: id,
      residentName: residentName,
      residentInitials: residentInitials,
      avatarColor: avatarColor,
      medicationName: medicationName,
      dose: dose,
      route: route,
      givenTimeLabel: givenTimeLabel,
      administeredByName: administeredByName,
      outcomeLabel: outcomeLabel,
      residenceName: residenceName ?? this.residenceName,
      wasLate: wasLate,
      administeredOnDuty: administeredOnDuty,
      witnessOnDuty: witnessOnDuty,
    );
  }
}

/// `GET /mar/administrations` list + web Given tab badge (`meta.total`).
@immutable
class MarAdministrationsList {
  final List<AdministeredDose> items;

  /// Server `meta.total` — same number the web puts on the Given tab.
  final int total;

  const MarAdministrationsList({
    required this.items,
    required this.total,
  });
}
