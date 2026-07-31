import 'package:gems_core/gems_core.dart';

import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/repositories/staff_incidents_repository.dart';

/// Local implementation of [StaffIncidentsRepository].
///
/// There is no backend endpoint for Staff Incidents yet, so this returns
/// the exact static content shown in the Figma "My Incidents", "All
/// Incidents", and "Incident Details" screenshots (see the feature's final
/// report for exactly which values are directly visible vs. reasonable
/// approximations).
class StaffIncidentsRepositoryImpl implements StaffIncidentsRepository {
  static const List<StaffIncident> _incidents = [
    StaffIncident(
      id: 'fall-no-injury-james-d',
      title: 'Fall – No Injury',
      iconKind: StaffIncidentIconKind.warning,
      severity: IncidentSeverity.low,
      dateTimeLabel: 'May 12, 2025 · 9:15 AM',
      personInitials: 'JD',
      personName: 'James D.',
      assignedNames: ['David L.'],
      status: IncidentStatus.open,
    ),
    StaffIncident(
      id: 'medication-refusal-robert-h',
      title: 'Medication Refusal',
      iconKind: StaffIncidentIconKind.info,
      severity: IncidentSeverity.medium,
      dateTimeLabel: 'May 11, 2025 · 7:30 PM',
      personInitials: 'RH',
      personName: 'Robert H.',
      assignedNames: ['Maria S.'],
      status: IncidentStatus.inReview,
    ),
    StaffIncident(
      id: 'verbal-aggression-michael-t',
      title: 'Verbal Aggression',
      iconKind: StaffIncidentIconKind.warning,
      severity: IncidentSeverity.high,
      dateTimeLabel: 'May 10, 2025 · 4:45 PM',
      personInitials: 'MT',
      personName: 'Michael T.',
      // NOTE: the source screenshot shows "Assigned: David L. +1" for this
      // card - "Alex R." is an approximation for the 2nd, unnamed assignee.
      assignedNames: ['David L.', 'Alex R.'],
      status: IncidentStatus.closed,
    ),
  ];

  // NOTE: only "Verbal Aggression" (#INC-2051) is directly visible in the
  // "Incident Details" screenshot. The other two incidents' details are
  // reasonable approximations that follow the same structure/tone, built
  // by analogy since no Figma access or matching screenshot exists for
  // them - flagged in the feature's final report.
  static const Map<String, IncidentDetail> _details = {
    'fall-no-injury-james-d': IncidentDetail(
      id: 'fall-no-injury-james-d',
      incidentCode: '#INC-2049',
      categoryLabel: 'SAFETY',
      title: 'Fall – No Injury',
      iconKind: StaffIncidentIconKind.warning,
      dateTimeLabel: 'May 12, 2025 · 9:15 AM',
      severity: IncidentSeverity.low,
      statusLabel: 'Resolved',
      detectedDuring: 'Morning round',
      location: 'Room 101',
      residentName: 'James D.',
      residentSubLabel: 'Room 101',
      residentInitials: 'JD',
      reportedByName: 'Priya Nair',
      reportedBySubLabel: 'Care Staff',
      reportedByInitials: 'PN',
    ),
    'medication-refusal-robert-h': IncidentDetail(
      id: 'medication-refusal-robert-h',
      incidentCode: '#INC-2050',
      categoryLabel: 'MEDICATION',
      title: 'Medication Refusal',
      iconKind: StaffIncidentIconKind.info,
      dateTimeLabel: 'May 11, 2025 · 7:30 PM',
      severity: IncidentSeverity.medium,
      statusLabel: 'Under Review',
      detectedDuring: 'Evening medication round',
      location: 'Room 108',
      residentName: 'Robert H.',
      residentSubLabel: 'Room 108',
      residentInitials: 'RH',
      reportedByName: 'Jordan Lee',
      reportedBySubLabel: 'Care Staff',
      reportedByInitials: 'JL',
    ),
    'verbal-aggression-michael-t': IncidentDetail(
      id: 'verbal-aggression-michael-t',
      incidentCode: '#INC-2051',
      categoryLabel: 'BEHAVIORAL',
      title: 'Verbal Aggression',
      iconKind: StaffIncidentIconKind.warning,
      dateTimeLabel: 'May 10, 2025 · 4:45 PM',
      severity: IncidentSeverity.high,
      statusLabel: 'Under Investigation',
      detectedDuring: 'Evening shift',
      location: 'Common area',
      residentName: 'Michael T.',
      residentSubLabel: 'Room 112',
      residentInitials: 'MT',
      // NOTE: the source screenshot cuts the 2nd "PEOPLE" row off right
      // after its heading (labeled "Reported by..." per the task brief) -
      // this name/role is a plausible approximation.
      reportedByName: 'Sarah Williams',
      reportedBySubLabel: 'Care Staff',
      reportedByInitials: 'SW',
    ),
  };

  @override
  Future<Result<List<StaffIncident>>> getIncidents() async {
    return Result.success(_incidents);
  }

  @override
  Future<Result<IncidentDetail>> getIncidentDetail(String incidentId) async {
    final detail = _details[incidentId];
    if (detail == null) {
      return Result.failure(UnknownError(message: 'Incident not found.'));
    }
    return Result.success(detail);
  }
}
