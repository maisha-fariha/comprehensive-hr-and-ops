import 'package:flutter/foundation.dart';

/// A charted dose (`GET /mar/administrations`) — the Given tab.
@immutable
class MarAdministration {
  final String id;
  final String medicationName;
  final String? dose;
  final bool isControlled;
  final String clientName;
  final String status;
  final DateTime? administeredAt;
  final String? administeredBy;
  final String? administeredByName;
  final String? witnessName;
  final bool wasLate;
  final bool? administeredOnDuty;
  final bool? witnessOnDuty;
  final String? amendsAdministrationId;
  final String? amendmentReason;
  final String? supersededById;

  const MarAdministration({
    required this.id,
    required this.medicationName,
    this.dose,
    this.isControlled = false,
    required this.clientName,
    required this.status,
    this.administeredAt,
    this.administeredBy,
    this.administeredByName,
    this.witnessName,
    this.wasLate = false,
    this.administeredOnDuty,
    this.witnessOnDuty,
    this.amendsAdministrationId,
    this.amendmentReason,
    this.supersededById,
  });

  bool get isSuperseded => supersededById != null && supersededById!.isNotEmpty;
}

/// A file picked for "Upload Supporting Evidence".
@immutable
class MarEvidenceFile {
  final String path;
  final String name;

  const MarEvidenceFile({required this.path, required this.name});
}

/// One medicine on the Record Administration round.
@immutable
class MarRoundItem {
  /// `MAR` (prescribed) or `PRN`.
  final String recordType;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String scheduledTime;
  final bool isControlled;
  final String status;
  final String doseReason;
  final String witnessStaffId;
  final String clinicalNotes;
  final String notes;
  final List<MarEvidenceFile> evidence;

  const MarRoundItem({
    this.recordType = 'MAR',
    this.medicationId = '',
    this.medicationName = '',
    this.dosage = '',
    this.scheduledTime = '',
    this.isControlled = false,
    this.status = 'administered',
    this.doseReason = '',
    this.witnessStaffId = '',
    this.clinicalNotes = '',
    this.notes = '',
    this.evidence = const [],
  });

  bool get isPrn => recordType == 'PRN';
}

/// `POST /mar/administrations/round` — one resident, any number of medicines.
@immutable
class MarRoundDraft {
  final String clientId;
  final String residenceId;
  final String staffId;
  final DateTime? administeredAt;

  /// The six point-of-administration checks, keyed as the API names them.
  final Map<String, bool> safetyChecks;

  /// Blood pressure, heart rate, temperature, blood sugar.
  final Map<String, String> vitals;
  final List<MarRoundItem> items;

  const MarRoundDraft({
    required this.clientId,
    required this.residenceId,
    required this.staffId,
    this.administeredAt,
    this.safetyChecks = const {},
    this.vitals = const {},
    required this.items,
  });
}
