import 'package:flutter/foundation.dart';

import 'incident_activity_entry.dart';
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
  final String description;
  final List<IncidentActivityEntry> activity;

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
    this.description = '',
    this.activity = const [],
  });

  /// Whether the red "supervisor review required" alert banner should show.
  bool get requiresUrgentReview =>
      severity == IncidentSeverity.high || severity == IncidentSeverity.critical;

  IncidentDetail copyWith({
    String? description,
    List<IncidentActivityEntry>? activity,
  }) {
    return IncidentDetail(
      id: id,
      incidentCode: incidentCode,
      categoryLabel: categoryLabel,
      title: title,
      iconKind: iconKind,
      dateTimeLabel: dateTimeLabel,
      severity: severity,
      statusLabel: statusLabel,
      detectedDuring: detectedDuring,
      location: location,
      residentName: residentName,
      residentSubLabel: residentSubLabel,
      residentInitials: residentInitials,
      reportedByName: reportedByName,
      reportedBySubLabel: reportedBySubLabel,
      reportedByInitials: reportedByInitials,
      description: description ?? this.description,
      activity: activity ?? this.activity,
    );
  }
}
