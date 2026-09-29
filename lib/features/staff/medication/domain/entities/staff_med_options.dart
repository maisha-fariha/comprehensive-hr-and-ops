import 'package:flutter/foundation.dart';

/// Residence option for Add Medicine / Record Administration pickers.
@immutable
class StaffMedResidenceOption {
  final String id;
  final String name;

  const StaffMedResidenceOption({required this.id, required this.name});
}

/// Client/resident option for Add Medicine.
@immutable
class StaffMedClientOption {
  final String id;
  final String name;
  final String? residenceId;
  final String? residenceName;

  const StaffMedClientOption({
    required this.id,
    required this.name,
    this.residenceId,
    this.residenceName,
  });
}

/// Payload for `POST /medications`.
@immutable
class StaffCreateMedicationInput {
  final String residenceId;
  final String clientId;
  final String name;
  final String? dose;
  final String? route;
  final int? stockUnitsPerDose;
  final String scheduleFrequency;
  final List<String> scheduleTimes;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isControlled;

  const StaffCreateMedicationInput({
    required this.residenceId,
    required this.clientId,
    required this.name,
    this.dose,
    this.route,
    this.stockUnitsPerDose,
    this.scheduleFrequency = 'daily',
    this.scheduleTimes = const [],
    this.startsAt,
    this.endsAt,
    this.isControlled = false,
  });
}

/// Payload for `POST /prn-medications`.
@immutable
class StaffCreatePrnMedicationInput {
  final String residenceId;
  final String? clientId;
  final String name;
  final String? dose;
  final String? route;
  final String? instructions;
  final int? stockUnitsPerDose;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isControlled;

  const StaffCreatePrnMedicationInput({
    required this.residenceId,
    this.clientId,
    required this.name,
    this.dose,
    this.route,
    this.instructions,
    this.stockUnitsPerDose,
    this.startsAt,
    this.endsAt,
    this.isControlled = false,
  });
}
