import 'package:flutter/foundation.dart';

import '../../../../hr/incidents/domain/entities/incident_investigation_summary.dart';
import 'incident_activity_entry.dart';
import 'incident_evidence_item.dart';
import 'staff_incidents_enums.dart';

/// Full read-only content for the Incident Details screen.
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
  final List<IncidentEvidenceItem> evidence;

  /// CIR payload + template snapshot for manager-style PDF generation.
  final IncidentInvestigationSummary? cirReport;

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
    this.evidence = const [],
    this.cirReport,
  });

  /// Whether the red "supervisor review required" alert banner should show.
  bool get requiresUrgentReview =>
      severity == IncidentSeverity.high || severity == IncidentSeverity.critical;

  IncidentDetail copyWith({
    String? description,
    List<IncidentActivityEntry>? activity,
    List<IncidentEvidenceItem>? evidence,
    IncidentInvestigationSummary? cirReport,
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
      evidence: evidence ?? this.evidence,
      cirReport: cirReport ?? this.cirReport,
    );
  }
}
