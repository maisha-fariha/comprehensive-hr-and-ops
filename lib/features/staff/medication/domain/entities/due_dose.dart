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
  /// Web registry `state` (due | upcoming | overdue | …) for filters.
  final String state;
  final String clientId;
  final String residenceId;
  final String residenceName;
  final String medicationId;
  final bool isPrn;

  /// False for a dose given outside a round (web "Unscheduled").
  final bool scheduled;

  /// Web `Morning` / `Afternoon` / `Evening` / `Night`.
  final String slotLabel;
  final String? administrationId;
  final DateTime? administeredAt;

  /// Staff id that signed the dose.
  final String? administeredBy;

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
    this.state = 'due',
    this.clientId = '',
    this.residenceId = '',
    this.residenceName = '',
    this.medicationId = '',
    this.isPrn = false,
    this.scheduled = true,
    this.slotLabel = '',
    this.administrationId,
    this.administeredAt,
    this.administeredBy,
  });

  DueDose copyWith({DueDoseStatus? status, String? state}) {
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
      state: state ?? this.state,
      clientId: clientId,
      residenceId: residenceId,
      residenceName: residenceName,
      medicationId: medicationId,
      isPrn: isPrn,
      scheduled: scheduled,
      slotLabel: slotLabel,
      administrationId: administrationId,
      administeredAt: administeredAt,
      administeredBy: administeredBy,
    );
  }
}
