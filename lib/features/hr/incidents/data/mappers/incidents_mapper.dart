import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/closed_incident.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/entities/open_incident.dart';

abstract final class IncidentsMapper {
  static IncidentsBoard compose({
    required dynamic listBody,
    required dynamic summaryBody,
  }) {
    final rows = JsonCodec.unwrapList(listBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
    final summary = JsonCodec.unwrapMap(summaryBody);
    final openRows = rows.where((row) => _bucket(row) == _Bucket.open).toList();
    final reviewRows =
        rows.where((row) => _bucket(row) == _Bucket.review).toList();
    final closedRows =
        rows.where((row) => _bucket(row) == _Bucket.closed).toList();
    final critical = openRows
        .where((row) => _severity(row['severity']) == IncidentSeverity.critical)
        .length;

    return IncidentsBoard(
      open: IncidentsOpenSection(
        activeCount: JsonCodec.integerOr(
          summary['open'] ?? summary['openCount'],
          openRows.length,
        ),
        stats: [
          IncidentStat(
            id: 'open-incidents',
            tag: IncidentStatTag.openIncidents,
            value: '${openRows.length}',
            label: 'Open Incidents',
          ),
          IncidentStat(
            id: 'critical-cases',
            tag: IncidentStatTag.criticalCases,
            value: '$critical',
            label: 'Critical Cases',
          ),
          IncidentStat(
            id: 'pending-review',
            tag: IncidentStatTag.pendingReview,
            value: '${reviewRows.length}',
            label: 'Pending Review',
          ),
        ],
        incidents: openRows.map(_open).toList(),
      ),
      underReview: IncidentsUnderReviewSection(
        investigationCount: JsonCodec.integerOr(
          summary['underReview'] ?? summary['investigating'],
          reviewRows.length,
        ),
        stats: [
          IncidentStat(
            id: 'under-review',
            tag: IncidentStatTag.underReview,
            value: '${reviewRows.length}',
            label: 'Under Review',
          ),
          IncidentStat(
            id: 'assigned-investigators',
            tag: IncidentStatTag.assignedInvestigators,
            value: '${reviewRows.where((row) => _investigator(row).isNotEmpty).length}',
            label: 'Assigned',
          ),
        ],
        incidents: reviewRows.map(_investigation).toList(),
      ),
      closed: IncidentsClosedSection(
        stats: [
          IncidentStat(
            id: 'resolved-today',
            tag: IncidentStatTag.resolvedToday,
            value: '${closedRows.length}',
            label: 'Resolved',
          ),
          IncidentStat(
            id: 'archived',
            tag: IncidentStatTag.archived,
            value: '${closedRows.where(_isArchived).length}',
            label: 'Archived',
          ),
        ],
        incidents: closedRows.map(_closed).toList(),
      ),
    );
  }

  static OpenIncident _open(Map<String, dynamic> json) {
    final client = _clientName(json);
    final reporter = _reporterName(json);
    final at = JsonCodec.dateTime(
      json['occurredAt'] ?? json['createdAt'] ?? json['reportedAt'],
    );
    return OpenIncident(
      id: JsonCodec.stringOr(json['id'], client),
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      iconKind: _icon(json),
      severity: _severity(json['severity']),
      subtitle: [
        client,
        JsonCodec.string(
          json['residenceName'] ?? JsonCodec.mapAt(json, 'residence')?['name'],
        ),
      ].whereType<String>().where((part) => part.isNotEmpty).join(' · '),
      statusLabel: JsonCodec.stringOr(json['status'], 'Open'),
      reportedAtLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
      reporterInitials: IsoDateRange.initials(reporter),
      reporterName: reporter,
    );
  }

  static InvestigationIncident _investigation(Map<String, dynamic> json) {
    final investigator = _investigator(json);
    final at = JsonCodec.dateTime(
      json['investigationStartedAt'] ?? json['updatedAt'] ?? json['createdAt'],
    );
    return InvestigationIncident(
      id: JsonCodec.stringOr(json['id'], 'incident'),
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      iconKind: _icon(json),
      statusLabel: JsonCodec.stringOr(json['status'], 'Under Review'),
      subtitle: _clientName(json),
      investigatorInitials: IsoDateRange.initials(investigator, fallback: '--'),
      investigatorName: investigator.isEmpty ? 'Unassigned' : investigator,
      startedAtLabel: at == null ? '' : IsoDateRange.dateTimeLabel(at),
    );
  }

  static ClosedIncident _closed(Map<String, dynamic> json) {
    final reviewer = json['reviewedBy'] ?? json['closedBy'] ?? json['resolver'];
    final reviewerName = reviewer == null ? null : IsoDateRange.personName(reviewer);
    final at = JsonCodec.dateTime(
      json['closedAt'] ?? json['resolvedAt'] ?? json['updatedAt'],
    );
    return ClosedIncident(
      id: JsonCodec.stringOr(json['id'], 'incident'),
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      iconKind: _icon(json),
      isArchived: _isArchived(json),
      subtitle: _clientName(json),
      dateLabel: at == null ? '' : IsoDateRange.formatShortDate(at.toLocal()),
      reviewerInitials:
          reviewerName == null ? null : IsoDateRange.initials(reviewerName),
      reviewerName: reviewerName,
    );
  }

  static String _clientName(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        {};
    return IsoDateRange.personName(
      client.isEmpty ? json['clientName'] ?? json['residentName'] : client,
    );
  }

  static String _reporterName(Map<String, dynamic> json) {
    final reporter = json['reporter'] ?? json['reportedBy'];
    return IsoDateRange.personName(
      reporter ?? json['reportedByName'] ?? json['reporterName'],
    );
  }

  static String _investigator(Map<String, dynamic> json) {
    final value = json['investigator'] ??
        json['assignedTo'] ??
        json['assignee'] ??
        (JsonCodec.listAt(json, 'assignees').isEmpty
            ? null
            : JsonCodec.listAt(json, 'assignees').first);
    if (value == null) return '';
    final name = IsoDateRange.personName(value);
    return name == 'Unknown' ? '' : name;
  }

  static bool _isArchived(Map<String, dynamic> json) {
    final status = (JsonCodec.string(json['status']) ?? '').toLowerCase();
    return status.contains('archive');
  }

  static IncidentSeverity _severity(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'critical':
        return IncidentSeverity.critical;
      case 'high':
        return IncidentSeverity.high;
      case 'medium':
        return IncidentSeverity.medium;
      default:
        return IncidentSeverity.low;
    }
  }

  static IncidentIconKind _icon(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(
              json['category'] ?? json['type'] ?? json['icon'],
            ) ??
            '')
        .toLowerCase();
    if (raw.contains('med')) return IncidentIconKind.bandage;
    if (raw.contains('fire') || raw.contains('flame')) {
      return IncidentIconKind.flame;
    }
    if (raw.contains('property') || raw.contains('home')) {
      return IncidentIconKind.home;
    }
    return IncidentIconKind.heart;
  }

  static _Bucket _bucket(Map<String, dynamic> json) {
    final status = (JsonCodec.string(json['status'] ?? json['state']) ?? '')
        .toLowerCase();
    if (status.contains('close') ||
        status.contains('resolv') ||
        status.contains('archive')) {
      return _Bucket.closed;
    }
    if (status.contains('review') ||
        status.contains('investigat') ||
        status.contains('assigned')) {
      return _Bucket.review;
    }
    return _Bucket.open;
  }

  const IncidentsMapper._();
}

enum _Bucket { open, review, closed }
