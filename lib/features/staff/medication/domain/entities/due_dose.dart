import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single dose card in the Due tab (Due Now / Later Today).
@immutable
class DueDose {
  final String id;
  final String residentName;
  final String residentInitials;
  final AvatarPalette avatarColor;
  final String medicationName;
  final String dose;
  final MedicationRoute route;
  final String timeLabel;
  final DueDoseSection section;
  final DueDoseStatus status;
  final String clientId;
  final String residenceId;
  final String medicationId;
  final bool isPrn;

  const DueDose({
    required this.id,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    required this.medicationName,
    required this.dose,
    required this.route,
    required this.timeLabel,
    required this.section,
    this.status = DueDoseStatus.pending,
    this.clientId = '',
    this.residenceId = '',
    this.medicationId = '',
    this.isPrn = false,
  });

  DueDose copyWith({DueDoseStatus? status}) {
    return DueDose(
      id: id,
      residentName: residentName,
      residentInitials: residentInitials,
      avatarColor: avatarColor,
      medicationName: medicationName,
      dose: dose,
      route: route,
      timeLabel: timeLabel,
      section: section,
      status: status ?? this.status,
      clientId: clientId,
      residenceId: residenceId,
      medicationId: medicationId,
      isPrn: isPrn,
    );
  }
}
