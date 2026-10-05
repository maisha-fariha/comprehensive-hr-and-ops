import 'package:flutter/foundation.dart';

/// A prescription (`GET /medications`) or a PRN medicine
/// (`GET /prn-medications`), normalised the way the web form reads both.
@immutable
class MarMedication {
  final String id;
  final bool isPrn;
  final String clientId;
  final String residenceId;
  final String name;
  final String? dose;
  final String frequency;
  final List<String> times;
  final List<int> weekdays;
  final String route;

  /// `YYYY-MM-DD`, empty when unset.
  final String startsAt;
  final String endsAt;
  final int? stockUnitsPerDose;
  final int? minIntervalMinutes;
  final String instructions;
  final bool isControlled;
  final String? requiresCheckScheduleId;
  final int? requiresCheckWithinMinutes;
  final bool isActive;
  final DateTime? lastAdministeredAt;

  const MarMedication({
    required this.id,
    this.isPrn = false,
    this.clientId = '',
    required this.residenceId,
    required this.name,
    this.dose,
    this.frequency = '',
    this.times = const [],
    this.weekdays = const [],
    this.route = '',
    this.startsAt = '',
    this.endsAt = '',
    this.stockUnitsPerDose,
    this.minIntervalMinutes,
    this.instructions = '',
    this.isControlled = false,
    this.requiresCheckScheduleId,
    this.requiresCheckWithinMinutes,
    this.isActive = true,
    this.lastAdministeredAt,
  });
}

/// The Add / Correct medicine form, one medicine at a time.
@immutable
class MarMedicineDraft {
  final bool isPrn;
  final String clientId;
  final String residenceId;
  final String name;
  final String dose;

  /// `daily` | `weekly` | `custom`.
  final String frequency;
  final List<String> times;
  final List<int> weekdays;
  final String route;

  /// `YYYY-MM-DD` or empty.
  final String startsAt;
  final String endsAt;
  final String stockUnitsPerDose;
  final String minIntervalMinutes;
  final String instructions;
  final bool isControlled;
  final String requiresCheckScheduleId;
  final String requiresCheckWithinMinutes;

  const MarMedicineDraft({
    this.isPrn = false,
    this.clientId = '',
    required this.residenceId,
    required this.name,
    this.dose = '',
    this.frequency = 'daily',
    this.times = const [],
    this.weekdays = const [],
    this.route = '',
    this.startsAt = '',
    this.endsAt = '',
    this.stockUnitsPerDose = '',
    this.minIntervalMinutes = '',
    this.instructions = '',
    this.isControlled = false,
    this.requiresCheckScheduleId = '',
    this.requiresCheckWithinMinutes = '60',
  });
}
