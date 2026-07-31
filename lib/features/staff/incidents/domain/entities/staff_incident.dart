import 'package:flutter/foundation.dart';

import 'staff_incidents_enums.dart';

/// A single row shown on both tabs of the Staff Incidents list screen.
///
/// The same 3 incidents back both the "My Incidents" and "All Incidents"
/// tabs in the Figma screenshots - only the footer content (resident/client
/// avatar+name vs. "Assigned: {staff}" text) and the presence of the
/// "View Details" button differ per tab, which the presentation widgets
/// handle rather than the model.
@immutable
class StaffIncident {
  final String id;
  final String title;
  final StaffIncidentIconKind iconKind;
  final IncidentSeverity severity;
  final String dateTimeLabel;

  /// The resident/client the incident concerns, shown with a small avatar
  /// next to the date on the "My Incidents" tab (e.g. avatar "JD" +
  /// "James D."). The source screenshot doesn't label this row, and cross
  /// referencing the sibling "Daily Note" screen confirms e.g. "James D."
  /// is a resident, not the reporting staff member - so this is modeled as
  /// the resident/client rather than a "reporter".
  final String personInitials;
  final String personName;

  /// Staff assigned to the incident, shown as "Assigned: {name}" (plus a
  /// "+N" suffix for extra assignees, e.g. "Assigned: David L. +1") on the
  /// "All Incidents" tab.
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
  });
}
