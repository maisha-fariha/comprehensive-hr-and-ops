import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/closed_incident.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/entities/open_incident.dart';

abstract final class IncidentsMapper {
  /// Parse `GET /residences` into dropdown options.
  static List<IncidentResidenceOption> residencesFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <IncidentResidenceOption>[];

    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ??
                json['label'] ??
                json['title'] ??
                json['residenceName'] ??
                json['displayName'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        IncidentResidenceOption(
          id: JsonCodec.stringOr(
            json['id'] ?? json['residenceId'] ?? name,
            name,
          ),
          name: name,
        ),
      );
    }
    return options;
  }

  /// Parse `GET /clients?search=` into typeahead options.
  static List<IncidentClientOption> clientsFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <IncidentClientOption>[];

    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final name = JsonCodec.string(
            json['preferredName'] ??
                json['fullName'] ??
                json['name'] ??
                json['displayName'] ??
                json['clientName'] ??
                json['residentName'],
          ) ??
          '';
      if (name.isEmpty) continue;

      final room = JsonCodec.string(
        json['room'] ?? json['roomNumber'] ?? json['location'],
      );
      final residenceName = JsonCodec.string(
        json['residenceName'] ?? residence['name'],
      );
      final subtitle = [
        if (room != null && room.isNotEmpty) room,
        if (residenceName != null && residenceName.isNotEmpty) residenceName,
      ].join(' · ');

      options.add(
        IncidentClientOption(
          id: JsonCodec.stringOr(json['id'] ?? json['clientId'], name),
          name: name,
          residenceId: JsonCodec.string(
            json['residenceId'] ?? residence['id'],
          ),
          residenceName: residenceName,
          subtitle: subtitle.isEmpty ? null : subtitle,
        ),
      );
    }
    return options;
  }

  /// Parse `GET /incident-categories` into dropdown options.
  static List<IncidentCategoryOption> categoriesFrom(dynamic body) {
    var source = JsonCodec.unwrapList(body);
    if (source.isEmpty) {
      final map = JsonCodec.unwrapMap(body);
      final nested = map['categories'] ?? map['items'] ?? map['results'];
      if (nested is List) source = nested;
      if (body is List) source = body;
    }

    final options = <IncidentCategoryOption>[];
    for (final item in source) {
      if (item is String) {
        final name = item.trim();
        if (name.isEmpty) continue;
        options.add(IncidentCategoryOption(id: name, name: name));
        continue;
      }
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ??
                json['label'] ??
                json['title'] ??
                json['category'] ??
                json['value'],
          ) ??
          '';
      if (name.isEmpty) continue;
      final id = JsonCodec.stringOr(
        json['id'] ?? json['categoryId'] ?? json['code'] ?? name,
        name,
      );
      options.add(IncidentCategoryOption(id: id, name: name));
    }
    return options;
  }

  /// Compose from a single mixed incidents list (legacy path).
  static IncidentsBoard compose({
    required dynamic listBody,
    required dynamic summaryBody,
  }) {
    final rows = JsonCodec.unwrapList(listBody)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
    return composeSections(
      openBody: rows.where((row) => _bucket(row) == _Bucket.open).toList(),
      reviewBody: rows.where((row) => _bucket(row) == _Bucket.review).toList(),
      closedBody: rows.where((row) => _bucket(row) == _Bucket.closed).toList(),
      summaryBody: summaryBody,
    );
  }

  /// Compose from status-scoped list responses.
  static IncidentsBoard composeSections({
    required dynamic openBody,
    required dynamic reviewBody,
    required dynamic closedBody,
    required dynamic summaryBody,
  }) {
    final openRows = _rows(openBody);
    final reviewRows = _rows(reviewBody);
    final closedRows = _rows(closedBody);
    final summary = JsonCodec.unwrapMap(summaryBody);
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
            value: '${_resolvedTodayCount(closedRows)}',
            label: 'Resolved Today',
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

  static List<Map<String, dynamic>> _rows(dynamic body) {
    if (body is List) {
      return body.whereType<Map>().map(JsonCodec.asMap).toList();
    }
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();
  }

  static int _resolvedTodayCount(List<Map<String, dynamic>> closedRows) {
    final now = DateTime.now();
    return closedRows.where((row) {
      final closedAt = JsonCodec.dateTime(
        row['closedAt'] ?? row['resolvedAt'] ?? row['updatedAt'],
      )?.toLocal();
      if (closedAt == null) return false;
      return closedAt.year == now.year &&
          closedAt.month == now.month &&
          closedAt.day == now.day;
    }).length;
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
        .toLowerCase()
        .replaceAll('-', '_');
    switch (status) {
      case 'closed':
      case 'resolved':
      case 'archived':
      case 'complete':
      case 'completed':
        return _Bucket.closed;
      case 'under_review':
      case 'in_review':
      case 'investigating':
      case 'investigation':
      case 'assigned':
      case 'pending_review':
        return _Bucket.review;
      case 'open':
      case 'new':
      case 'reported':
      case 'active':
        return _Bucket.open;
      default:
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
  }

  const IncidentsMapper._();
}

enum _Bucket { open, review, closed }
