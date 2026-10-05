import 'package:flutter/foundation.dart';

import 'staff_incidents_enums.dart';

/// A single row on the Staff Incidents list (web table columns, mobile card).
@immutable
class StaffIncident {
  final String id;
  final String title;
  final String categoryLabel;
  final String residenceName;
  final String reportedByName;
  final String reportedAtLabel;
  final String? acknowledgedAtLabel;
  final bool acknowledged;
  final StaffIncidentIconKind iconKind;
  final IncidentSeverity severity;
  final String dateTimeLabel;

  /// Resident/client the incident concerns.
  final String personInitials;
  final String personName;

  /// Staff assigned (All Incidents footer).
  final List<String> assignedNames;

  final IncidentStatus status;

  const StaffIncident({
    required this.id,
    required this.title,
    required this.iconKind,
    required this.severity,
    required this.dateTimeLabel,
    required this.personInitials,
    required this.personName,
    required this.assignedNames,
    required this.status,
    this.categoryLabel = '',
    this.residenceName = '',
    this.reportedByName = '',
    this.reportedAtLabel = '',
    this.acknowledgedAtLabel,
    this.acknowledged = false,
  });

  String get shortId {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}
