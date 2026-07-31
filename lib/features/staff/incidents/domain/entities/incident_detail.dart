import 'package:flutter/foundation.dart';

import 'staff_incidents_enums.dart';

/// Full read-only content for the Incident Details screen, reached by
/// tapping "View Details" on an "All Incidents" card.
@immutable
class IncidentDetail {
  final String id;
  final String incidentCode;
  final String categoryLabel;
  final String title;
  final StaffIncidentIconKind iconKind;
  final String dateTimeLabel;
  final IncidentSeverity severity;

  /// Freeform investigation-status pill text (e.g. "Under Investigation").
  /// Kept as a plain string rather than [IncidentStatus] because the
  /// source screenshot's value doesn't map 1:1 onto the list's
  /// Open/In Review/Closed vocabulary.
  final String statusLabel;

  final String detectedDuring;
  final String location;

  final String residentName;
  final String residentSubLabel;
  final String residentInitials;

  final String reportedByName;
  final String reportedBySubLabel;
  final String reportedByInitials;

  const IncidentDetail({
    required this.id,
    required this.incidentCode,
    required this.categoryLabel,
    required this.title,
    required this.iconKind,
    required this.dateTimeLabel,
    required this.severity,
    required this.statusLabel,
    required this.detectedDuring,
    required this.location,
    required this.residentName,
    required this.residentSubLabel,
    required this.residentInitials,
    required this.reportedByName,
    required this.reportedBySubLabel,
    required this.reportedByInitials,
  });

  /// Whether the red "supervisor review required" alert banner should show.
  bool get requiresUrgentReview =>
      severity == IncidentSeverity.high || severity == IncidentSeverity.critical;
}
