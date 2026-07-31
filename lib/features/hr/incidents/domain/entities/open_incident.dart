import 'package:flutter/foundation.dart';

import 'incidents_enums.dart';

/// A single row in the "Active Incidents" list on the Open tab.
@immutable
class OpenIncident {
  final String id;
  final String title;
  final IncidentIconKind iconKind;
  final IncidentSeverity severity;
  final String subtitle;
  final String statusLabel;
  final String reportedAtLabel;
  final String reporterInitials;
  final String reporterName;

  const OpenIncident({
    required this.id,
    required this.title,
    required this.iconKind,
    required this.severity,
    required this.subtitle,
    required this.statusLabel,
    required this.reportedAtLabel,
    required this.reporterInitials,
    required this.reporterName,
  });
}
