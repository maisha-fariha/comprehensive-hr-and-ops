import 'package:flutter/foundation.dart';

/// Residence option for Add Medicine / Record Administration pickers.
@immutable
class StaffMedResidenceOption {
  final String id;
  final String name;

  const StaffMedResidenceOption({required this.id, required this.name});

  /// Dropdowns match their value against reloaded items, so identity is the id.
  @override
  bool operator ==(Object other) =>
      other is StaffMedResidenceOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
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

  @override
  bool operator ==(Object other) =>
      other is StaffMedClientOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Recurring-check schedule option for "Requires a check first".
@immutable
class StaffMedCheckOption {
  final String id;
  final String name;

  const StaffMedCheckOption({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is StaffMedCheckOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Payload for `POST /medications` and `PATCH /medications/:id`.
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
  final List<int> scheduleWeekdays;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isControlled;
  final String? requiresCheckScheduleId;
  final int? requiresCheckWithinMinutes;

  const StaffCreateMedicationInput({
    required this.residenceId,
    required this.clientId,
    required this.name,
    this.dose,
    this.route,
    this.stockUnitsPerDose,
    this.scheduleFrequency = 'daily',
    this.scheduleTimes = const [],
    this.scheduleWeekdays = const [],
    this.startsAt,
    this.endsAt,
    this.isControlled = false,
    this.requiresCheckScheduleId,
    this.requiresCheckWithinMinutes,
  });
}

/// Payload for `POST /prn-medications` and `PATCH /prn-medications/:id`.
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
  final int? minIntervalMinutes;
  final String? requiresCheckScheduleId;
  final int? requiresCheckWithinMinutes;

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
    this.minIntervalMinutes,
    this.requiresCheckScheduleId,
    this.requiresCheckWithinMinutes,
  });
}
