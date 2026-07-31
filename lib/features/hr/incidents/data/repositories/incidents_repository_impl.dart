import 'package:gems_core/gems_core.dart';

import '../../domain/entities/closed_incident.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/entities/open_incident.dart';
import '../../domain/repositories/incidents_repository.dart';

/// Local implementation of [IncidentsRepository].
///
/// There is no backend endpoint for Incidents yet, so this returns the
/// exact static content shown in the Figma design / reference screenshots.
/// Replace the body of [getBoard] with a real `ApiService`/`BaseRepository`
/// call once an API contract exists - the domain layer and every widget
/// above it will keep working unchanged.
///
/// A few fields are reasonable approximations rather than directly-visible
/// Figma values, because the source screenshots cut the underlying list off
/// mid-card (the app only had visual references, not exact Figma
/// measurements, for these two screens) - see the inline notes below.
class IncidentsRepositoryImpl implements IncidentsRepository {
  @override
  Future<Result<IncidentsBoard>> getBoard() async {
    return Result.success(
      const IncidentsBoard(
        open: IncidentsOpenSection(
          activeCount: 4,
          stats: [
            IncidentStat(
              id: 'open-incidents',
              tag: IncidentStatTag.openIncidents,
              value: '4',
              label: 'Open Incidents',
            ),
            IncidentStat(
              id: 'critical-cases',
              tag: IncidentStatTag.criticalCases,
              value: '1',
              label: 'Critical Cases',
            ),
            IncidentStat(
              id: 'pending-review',
              tag: IncidentStatTag.pendingReview,
              value: '3',
              label: 'Pending Review',
            ),
          ],
          incidents: [
            OpenIncident(
              id: 'client-altercation-sarah-c',
              title: 'Client Altercation',
              iconKind: IncidentIconKind.heart,
              severity: IncidentSeverity.critical,
              subtitle: 'Sarah C. · Sunrise Home',
              statusLabel: 'Pending Review',
              reportedAtLabel: 'Today, 8:35 AM',
              reporterInitials: 'MT',
              reporterName: 'Mike T.',
            ),
            OpenIncident(
              id: 'medication-error-arthur-m',
              title: 'Medication Error',
              iconKind: IncidentIconKind.bandage,
              severity: IncidentSeverity.high,
              subtitle: 'Arthur M. · Maple Court',
              statusLabel: 'Pending Review',
              reportedAtLabel: 'Today, 7:20 AM',
              reporterInitials: 'SW',
              reporterName: 'Sarah W.',
            ),
            // NOTE: the source screenshot cuts this 3rd card off right
            // after the title/severity pill (title "Property Damage" and
            // severity "MEDIUM" are directly visible; the subtitle, status,
            // reporter and time below are a reasonable approximation
            // following the same pattern as the two fully-visible cards
            // above, per the task's guidance that close approximation is
            // acceptable pending a real screenshot/Figma access).
            OpenIncident(
              id: 'property-damage-approx',
              title: 'Property Damage',
              iconKind: IncidentIconKind.home,
              severity: IncidentSeverity.medium,
              subtitle: 'Robert K. · Sunrise Home',
              statusLabel: 'Pending Review',
              reportedAtLabel: 'Today, 6:45 AM',
              reporterInitials: 'AR',
              reporterName: 'Alex R.',
            ),
          ],
        ),
        underReview: IncidentsUnderReviewSection(
          investigationCount: 3,
          stats: [
            IncidentStat(
              id: 'under-review',
              tag: IncidentStatTag.underReview,
              value: '3',
              label: 'Under Review',
            ),
            IncidentStat(
              id: 'assigned-investigators',
              tag: IncidentStatTag.assignedInvestigators,
              value: '4',
              label: 'Assigned Investigators',
            ),
            IncidentStat(
              id: 'pending-actions',
              tag: IncidentStatTag.pendingActions,
              value: '5',
              label: 'Pending Actions',
            ),
          ],
          incidents: [
            InvestigationIncident(
              id: 'medication-error-arthur-morgan',
              title: 'Medication Error',
              iconKind: IncidentIconKind.bandage,
              statusLabel: 'Ongoing',
              subtitle: 'Client · Arthur Morgan',
              investigatorInitials: 'SW',
              investigatorName: 'Sarah Williams',
              startedAtLabel: 'Today 10:30 AM',
            ),
            InvestigationIncident(
              id: 'client-altercation-sarah-connor',
              title: 'Client Altercation',
              iconKind: IncidentIconKind.heart,
              statusLabel: 'Ongoing',
              subtitle: 'Client · Sarah Connor',
              investigatorInitials: 'DO',
              investigatorName: 'David Okoro',
              startedAtLabel: 'Today 9:05 AM',
            ),
          ],
        ),
        closed: IncidentsClosedSection(
          stats: [
            IncidentStat(
              id: 'resolved-today',
              tag: IncidentStatTag.resolvedToday,
              value: '6',
              label: 'Resolved Today',
            ),
            IncidentStat(
              id: 'this-week',
              tag: IncidentStatTag.thisWeek,
              value: '21',
              label: 'This Week',
            ),
            IncidentStat(
              id: 'archived',
              tag: IncidentStatTag.archived,
              value: '148',
              label: 'Archived',
            ),
          ],
          incidents: [
            ClosedIncident(
              id: 'fall-no-injury-james-d',
              title: 'Fall — No Injury',
              iconKind: IncidentIconKind.flame,
              isArchived: false,
              subtitle: 'Client · James D.',
              dateLabel: 'May 12, 2025',
              reviewerInitials: 'DO',
              reviewerName: 'David Okoro',
            ),
            ClosedIncident(
              id: 'medication-refusal-arthur-morgan',
              title: 'Medication Refusal',
              iconKind: IncidentIconKind.bandage,
              isArchived: false,
              subtitle: 'Client · Arthur Morgan',
              dateLabel: 'May 11, 2025',
              reviewerInitials: 'SW',
              reviewerName: 'Sarah Williams',
            ),
            // NOTE: the source screenshot cuts this 3rd card off right
            // after the title/subtitle/"Archived" pill - the archive date
            // below is an approximation (no reviewer is shown for archived
            // incidents in the visible portion, so none is modeled here).
            ClosedIncident(
              id: 'property-damage-john-marston',
              title: 'Property Damage',
              iconKind: IncidentIconKind.home,
              isArchived: true,
              subtitle: 'Client · John Marston',
              dateLabel: 'May 3, 2025',
            ),
          ],
        ),
      ),
    );
  }
}
