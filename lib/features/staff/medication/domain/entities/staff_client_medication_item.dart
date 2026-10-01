import 'package:flutter/foundation.dart';

/// Prescribed or PRN medication for a client
/// (`GET /medications?clientId=` / `GET /prn-medications?clientId=`).
@immutable
class StaffClientMedicationItem {
  final String id;
  final String name;
  final String dose;
  final String? scheduleLabel;
  final String? instructions;
  final bool isPrn;
  final String clientId;
  final String clientName;
  final String residenceId;
  final String residenceName;

  /// Raw record fields the Edit form is prefilled from.
  final String route;
  final String frequency;
  final List<String> times;
  final List<int> weekdays;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? stockUnitsPerDose;
  final int? minIntervalMinutes;
  final bool isControlled;
  final String? requiresCheckScheduleId;
  final int? requiresCheckWithinMinutes;
  final bool isActive;

  const StaffClientMedicationItem({
    required this.id,
    required this.name,
    required this.dose,
    this.scheduleLabel,
    this.instructions,
    this.isPrn = false,
    this.clientId = '',
    this.clientName = '',
    this.residenceId = '',
    this.residenceName = '',
    this.route = '',
    this.frequency = 'daily',
    this.times = const [],
    this.weekdays = const [],
    this.startsAt,
    this.endsAt,
    this.stockUnitsPerDose,
    this.minIntervalMinutes,
    this.isControlled = false,
    this.requiresCheckScheduleId,
    this.requiresCheckWithinMinutes,
    this.isActive = true,
  });

  StaffClientMedicationItem copyWith({
    String? clientName,
    String? residenceName,
  }) {
    return StaffClientMedicationItem(
      id: id,
      name: name,
      dose: dose,
      scheduleLabel: scheduleLabel,
      instructions: instructions,
      isPrn: isPrn,
      clientId: clientId,
      clientName: clientName ?? this.clientName,
      residenceId: residenceId,
      residenceName: residenceName ?? this.residenceName,
      route: route,
      frequency: frequency,
      times: times,
      weekdays: weekdays,
      startsAt: startsAt,
      endsAt: endsAt,
      stockUnitsPerDose: stockUnitsPerDose,
      minIntervalMinutes: minIntervalMinutes,
      isControlled: isControlled,
      requiresCheckScheduleId: requiresCheckScheduleId,
      requiresCheckWithinMinutes: requiresCheckWithinMinutes,
      isActive: isActive,
    );
  }

  /// Dropdowns match their value against reloaded items, so identity is the
  /// record id (a prescription and a PRN can never share one).
  @override
  bool operator ==(Object other) =>
      other is StaffClientMedicationItem &&
      other.id == id &&
      other.isPrn == isPrn;

  @override
  int get hashCode => Object.hash(id, isPrn);
}
