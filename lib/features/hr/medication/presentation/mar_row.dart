import 'package:flutter/material.dart';

import '../domain/entities/mar_medication.dart';
import '../domain/entities/mar_round.dart';
import 'medication_labels.dart';

/// A registry row, shaped like the web table entry for both the MAR tab
/// (a dose on today's round) and the PRN tab (an as-needed medicine).
@immutable
class MarRow {
  final String id;

  /// `MAR` or `PRN`.
  final String recordType;
  final String medicationId;
  final String clientId;
  final String residentName;
  final String residentInitials;
  final Color avatarColor;
  final List<String> allergies;
  final String residenceId;
  final String residence;
  final String medication;
  final Color dotColor;
  final String dosage;
  final bool isControlled;
  final String scheduleSlot;
  final String scheduleTime;
  final DateTime? dueAt;
  final String lastAdministered;
  final String? administeredBy;
  final String nextDue;
  final String? state;
  final String statusLabel;
  final String? administrationId;

  const MarRow({
    required this.id,
    required this.recordType,
    required this.medicationId,
    required this.clientId,
    required this.residentName,
    required this.residentInitials,
    required this.avatarColor,
    this.allergies = const [],
    required this.residenceId,
    required this.residence,
    required this.medication,
    required this.dotColor,
    required this.dosage,
    this.isControlled = false,
    required this.scheduleSlot,
    required this.scheduleTime,
    this.dueAt,
    required this.lastAdministered,
    this.administeredBy,
    required this.nextDue,
    this.state,
    required this.statusLabel,
    this.administrationId,
  });

  bool get isPrn => recordType == 'PRN';

  factory MarRow.fromOccurrence(
    MarOccurrence o, {
    Map<String, String> staffNames = const {},
  }) {
    final name = o.clientName ?? 'Unnamed resident';
    final unscheduled = !o.scheduled;
    final due = o.dueAt;
    return MarRow(
      id: o.id,
      recordType: 'MAR',
      medicationId: o.medicationId,
      clientId: o.clientId,
      residentName: name,
      residentInitials: MedicationLabels.initials(name),
      avatarColor: MedicationLabels.colorFor(o.clientId),
      allergies: o.allergies,
      residenceId: o.residenceId,
      residence: o.residenceName ?? '—',
      medication: o.name,
      dotColor: MedicationLabels.colorFor(o.medicationId),
      dosage: o.dose ?? '—',
      isControlled: o.isControlled,
      scheduleSlot: MedicationLabels.slotFor(
        unscheduled && due != null ? MedicationLabels.time(due) : o.scheduledTime,
      ),
      scheduleTime: unscheduled ? 'Unscheduled' : o.scheduledTime,
      dueAt: due,
      lastAdministered:
          o.administeredAt == null ? '—' : MedicationLabels.dateTime(o.administeredAt),
      administeredBy: o.administeredBy == null ? null : staffNames[o.administeredBy],
      nextDue: unscheduled
          ? '—'
          : (o.state == 'given' || o.state == 'late' ? 'Tomorrow' : o.scheduledTime),
      state: o.state,
      statusLabel: MedicationLabels.states[o.state] ?? o.state,
      administrationId: o.administrationId,
    );
  }

  factory MarRow.fromPrn(
    MarMedication p, {
    required Map<String, String> clientNames,
    required Map<String, String> residenceNames,
  }) {
    final houseStock = p.clientId.isEmpty;
    final name =
        houseStock ? 'House stock' : (clientNames[p.clientId] ?? 'Outside your access');
    return MarRow(
      id: p.id,
      recordType: 'PRN',
      medicationId: p.id,
      clientId: p.clientId,
      residentName: name,
      residentInitials: houseStock ? 'HS' : MedicationLabels.initials(name),
      avatarColor: MedicationLabels.colorFor(houseStock ? p.residenceId : p.clientId),
      residenceId: p.residenceId,
      residence: residenceNames[p.residenceId] ?? '—',
      medication: p.name,
      dotColor: MedicationLabels.colorFor(p.id),
      dosage: p.dose ?? '—',
      isControlled: p.isControlled,
      scheduleSlot: 'As Needed',
      scheduleTime: p.instructions.isNotEmpty ? p.instructions : 'On request',
      lastAdministered: p.lastAdministeredAt == null
          ? 'Never given'
          : MedicationLabels.dateTime(p.lastAdministeredAt),
      nextDue: '—',
      statusLabel: p.isActive ? 'Available' : 'Discontinued',
    );
  }
}

/// A medicine the Record Administration form can chart (the web `tr` list).
@immutable
class MarMedicationChoice {
  final String id;
  final String label;
  final String recordType;
  final String clientId;
  final String residenceId;
  final String dosage;
  final bool isControlled;
  final String scheduledTime;

  const MarMedicationChoice({
    required this.id,
    required this.label,
    required this.recordType,
    required this.clientId,
    required this.residenceId,
    required this.dosage,
    required this.isControlled,
    required this.scheduledTime,
  });
}

/// `[humanise(frequency), times]` joined with ` · `, like the web.
String marScheduleLabel(MarMedication m) => [
      MedicationLabels.humanise(m.frequency),
      m.times.join(', '),
    ].where((e) => e.isNotEmpty && e != '—').join(' · ');
