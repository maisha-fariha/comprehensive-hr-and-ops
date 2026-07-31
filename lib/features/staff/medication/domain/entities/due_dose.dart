import 'package:flutter/foundation.dart';

import 'staff_medication_enums.dart';

/// A single dose card in the "Due" tab, e.g. "James D. — Lisinopril 10mg —
/// Tablet · Oral — 9:00 AM" with an "Administer"/"Not Given" action row.
///
/// [status] is intentionally mutable via [copyWith] (rather than a plain
/// `const` field) so the controller can flip a card from [DueDoseStatus.pending]
/// to [DueDoseStatus.administered]/[DueDoseStatus.notGiven] in local mock
/// state when a staff member taps a button — there is no backend for this
/// screen yet.
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
    );
  }
}
