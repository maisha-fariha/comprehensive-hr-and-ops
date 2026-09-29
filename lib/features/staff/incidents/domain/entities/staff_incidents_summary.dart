import 'package:flutter/foundation.dart';

import 'staff_incident.dart';

/// Counts + side panels from `GET /incidents/summary` (web Incident Reports).
@immutable
class StaffIncidentsSummary {
  final int total;
  final int open;
  final int investigating;
  final int closed;
  /// High + critical combined (web "High or Critical" / `serious`).
  final int serious;
  final int awaitingInvestigation;
  final int openInvestigations;
  final List<StaffIncidentWatchlistItem> watchlist;
  final List<StaffIncidentQueueItem> investigationQueue;

  const StaffIncidentsSummary({
    this.total = 0,
    this.open = 0,
    this.investigating = 0,
    this.closed = 0,
    this.serious = 0,
    this.awaitingInvestigation = 0,
    this.openInvestigations = 0,
    this.watchlist = const [],
    this.investigationQueue = const [],
  });

  static const empty = StaffIncidentsSummary();
}

/// Critical Watchlist row from summary payload.
@immutable
class StaffIncidentWatchlistItem {
  final String id;
  final String title;
  final String residence;
  final String client;
  final String severityLabel;
  final String stageLabel;
  final bool hasInvestigation;
  final bool acknowledged;

  const StaffIncidentWatchlistItem({
    required this.id,
    required this.title,
    this.residence = '',
    this.client = '',
    this.severityLabel = '',
    this.stageLabel = 'Not started',
    this.hasInvestigation = false,
    this.acknowledged = false,
  });
}

/// Investigation Queue row from summary payload.
@immutable
class StaffIncidentQueueItem {
  final String id;
  final String caseName;
  final String stage;
  final String? investigator;

  const StaffIncidentQueueItem({
    required this.id,
    required this.caseName,
    this.stage = '',
    this.investigator,
  });
}

/// Convenience re-export for panels that open a list row.
typedef StaffIncidentSummaryIncident = StaffIncident;
