import 'package:flutter/foundation.dart';

/// One dose on today's round (`GET /mar/round` → `occurrences[]`).
@immutable
class MarOccurrence {
  final String id;
  final String medicationId;
  final String clientId;
  final String? clientName;
  final List<String> allergies;
  final String residenceId;
  final String? residenceName;
  final String name;
  final String? dose;
  final bool isControlled;
  final String scheduledTime;
  final DateTime? dueAt;
  final String state;

  /// False for a dose given outside a round.
  final bool scheduled;
  final String? administrationId;
  final DateTime? administeredAt;
  final String? administeredBy;

  const MarOccurrence({
    required this.id,
    required this.medicationId,
    required this.clientId,
    this.clientName,
    this.allergies = const [],
    required this.residenceId,
    this.residenceName,
    required this.name,
    this.dose,
    this.isControlled = false,
    required this.scheduledTime,
    this.dueAt,
    this.state = 'upcoming',
    this.scheduled = true,
    this.administrationId,
    this.administeredAt,
    this.administeredBy,
  });
}

/// `GET /mar/round` → `summary`; feeds the four KPI cards.
@immutable
class MarSummary {
  final int scheduled;
  final int administered;
  final int unscheduled;
  final int missed;
  final int? complianceRate;

  const MarSummary({
    this.scheduled = 0,
    this.administered = 0,
    this.unscheduled = 0,
    this.missed = 0,
    this.complianceRate,
  });
}

@immutable
class MarRound {
  final List<MarOccurrence> occurrences;
  final MarSummary summary;

  const MarRound({this.occurrences = const [], this.summary = const MarSummary()});
}

/// An as-needed medicine on a resident chart.
@immutable
class MarChartPrn {
  final String id;
  final String name;
  final DateTime? lastAdministeredAt;
  final int? minIntervalMinutes;
  final int? availableInMinutes;

  const MarChartPrn({
    required this.id,
    required this.name,
    this.lastAdministeredAt,
    this.minIntervalMinutes,
    this.availableInMinutes,
  });
}

/// `GET /mar/residents/:clientId/chart` — one person's day.
@immutable
class MarResidentChart {
  final List<String> allergies;

  /// Keyed `morning` / `afternoon` / `evening` / `night`.
  final Map<String, List<MarOccurrence>> buckets;
  final List<MarOccurrence> unscheduled;
  final List<MarChartPrn> prn;

  const MarResidentChart({
    this.allergies = const [],
    this.buckets = const {},
    this.unscheduled = const [],
    this.prn = const [],
  });
}
