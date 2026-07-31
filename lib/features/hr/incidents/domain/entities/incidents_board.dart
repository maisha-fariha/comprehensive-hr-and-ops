import 'package:flutter/foundation.dart';

import 'closed_incident.dart';
import 'incident_stat.dart';
import 'investigation_incident.dart';
import 'open_incident.dart';

/// Content for the "Open" tab of the Incidents list.
@immutable
class IncidentsOpenSection {
  final List<IncidentStat> stats;
  final List<OpenIncident> incidents;

  /// Total active-incident count shown in the "Active Incidents" section
  /// badge (and reused for the "Open" tab's inactive-tab badge). Kept
  /// separate from `incidents.length` because the source screen is a
  /// scrollable list - only the incidents visible in the captured
  /// screenshot are modeled here, while this total mirrors what Figma
  /// displays.
  final int activeCount;

  const IncidentsOpenSection({
    required this.stats,
    required this.incidents,
    required this.activeCount,
  });
}

/// Content for the "Under Review" tab of the Incidents list.
@immutable
class IncidentsUnderReviewSection {
  final List<IncidentStat> stats;
  final List<InvestigationIncident> incidents;

  /// Total in-investigation count shown in the "In Investigation" section
  /// badge. See [IncidentsOpenSection.activeCount] for why this is
  /// decoupled from `incidents.length`.
  final int investigationCount;

  const IncidentsUnderReviewSection({
    required this.stats,
    required this.incidents,
    required this.investigationCount,
  });
}

/// Content for the "Closed" tab of the Incidents list.
@immutable
class IncidentsClosedSection {
  final List<IncidentStat> stats;
  final List<ClosedIncident> incidents;

  const IncidentsClosedSection({
    required this.stats,
    required this.incidents,
  });
}

/// Aggregate root for everything shown on the Incidents list screen (all 3
/// tabs), mirroring how `DashboardOverview` aggregates the Dashboard.
@immutable
class IncidentsBoard {
  final IncidentsOpenSection open;
  final IncidentsUnderReviewSection underReview;
  final IncidentsClosedSection closed;

  const IncidentsBoard({
    required this.open,
    required this.underReview,
    required this.closed,
  });
}
