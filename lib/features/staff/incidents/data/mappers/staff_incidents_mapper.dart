import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/incident_activity_entry.dart';
import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incidents_enums.dart';

abstract final class StaffIncidentsMapper {
  static List<StaffIncident> listFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .whereType<Map>()
        .map((item) => fromListJson(JsonCodec.asMap(item)))
        .toList();
  }

  static StaffIncident fromListJson(Map<String, dynamic> json) {
    final client = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        {};
    final name = JsonCodec.stringOr(
      client['preferredName'] ??
          client['name'] ??
          json['clientName'] ??
          json['residentName'],
      'Resident',
    );
    final assignees = JsonCodec.listAt(json, 'assignees').isEmpty
        ? JsonCodec.listAt(json, 'assignedStaff')
        : JsonCodec.listAt(json, 'assignees');
    final occurred = JsonCodec.dateTime(
      json['occurredAt'] ?? json['createdAt'] ?? json['reportedAt'],
    );

    return StaffIncident(
      id: JsonCodec.stringOr(json['id'], name),
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      iconKind: _iconKind(json),
      severity: _severity(json['severity']),
      dateTimeLabel: occurred == null
          ? JsonCodec.stringOr(json['dateLabel'], '')
          : '${IsoDateRange.formatShortDate(occurred.toLocal())} · ${IsoDateRange.timeLabel(occurred.toLocal())}',
      personInitials: IsoDateRange.initials(name),
      personName: name,
      assignedNames: assignees
          .map(IsoDateRange.personName)
          .where((item) => item != 'Unknown')
          .toList(),
      status: _status(json['status']),
    );
  }

  static IncidentDetail detailFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final list = fromListJson(json);
    final client = JsonCodec.mapAt(json, 'client') ??
        JsonCodec.mapAt(json, 'resident') ??
        {};
    final reporter = JsonCodec.mapAt(json, 'reporter') ??
        JsonCodec.mapAt(json, 'reportedBy') ??
        {};
    final reporterName = IsoDateRange.personName(
      reporter.isEmpty ? json['reportedByName'] : reporter,
    );

    return IncidentDetail(
      id: list.id,
      incidentCode: JsonCodec.stringOr(
        json['code'] ?? json['incidentCode'] ?? json['cirNumber'],
        list.id,
      ),
      categoryLabel: JsonCodec.stringOr(
        json['category'] ??
            JsonCodec.mapAt(json, 'category')?['name'] ??
            json['categoryName'],
        'Incident',
      ),
      title: list.title,
      iconKind: list.iconKind,
      dateTimeLabel: list.dateTimeLabel,
      severity: list.severity,
      statusLabel: _statusLabel(list.status),
      detectedDuring: JsonCodec.stringOr(
        json['detectedDuring'] ?? json['shift'] ?? json['context'],
        '',
      ),
      location: JsonCodec.stringOr(json['location'] ?? json['room'], ''),
      residentName: list.personName,
      residentSubLabel: JsonCodec.stringOr(
        client['room'] ?? client['roomNumber'] ?? json['room'],
        '',
      ),
      residentInitials: list.personInitials,
      reportedByName: reporterName,
      reportedBySubLabel: JsonCodec.stringOr(
        reporter['role'] ?? reporter['title'] ?? json['reportedByRole'],
        '',
      ),
      reportedByInitials: IsoDateRange.initials(reporterName),
      description: JsonCodec.stringOr(
        json['description'] ?? json['body'] ?? json['narrative'],
        '',
      ),
      activity: activityFrom(json['activity'] ?? json['activities']),
    );
  }

  static List<IncidentActivityEntry> activityFrom(dynamic body) {
    final items = JsonCodec.unwrapList(body);
    return [
      for (var i = 0; i < items.length; i++)
        if (items[i] is Map)
          _activityRow(JsonCodec.asMap(items[i] as Map), isActive: i == 0),
    ];
  }

  static IncidentActivityEntry _activityRow(
    Map<String, dynamic> json, {
    required bool isActive,
  }) {
    final at = JsonCodec.dateTime(
      json['createdAt'] ?? json['occurredAt'] ?? json['at'],
    );
    final actor = IsoDateRange.personName(
      json['actor'] ?? json['user'] ?? json['staff'] ?? json['performedBy'],
    );
    return IncidentActivityEntry(
      title: JsonCodec.stringOr(
        json['title'] ?? json['action'] ?? json['type'] ?? json['event'],
        'Update',
      ),
      meta: [
        if (actor != 'Unknown') actor,
        if (at != null)
          '${IsoDateRange.formatShortDate(at.toLocal())}, ${IsoDateRange.timeLabel(at.toLocal())}',
      ].join('  •  '),
      isActive: isActive,
    );
  }

  static StaffIncidentIconKind _iconKind(Map<String, dynamic> json) {
    final raw = (JsonCodec.string(json['category']) ??
            JsonCodec.string(json['type']) ??
            JsonCodec.string(json['title']) ??
            '')
        .toLowerCase();
    if (raw.contains('medication') || raw.contains('care')) {
      return StaffIncidentIconKind.info;
    }
    return StaffIncidentIconKind.warning;
  }

  static IncidentSeverity _severity(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'critical':
        return IncidentSeverity.critical;
      case 'high':
        return IncidentSeverity.high;
      case 'medium':
      case 'moderate':
        return IncidentSeverity.medium;
      default:
        return IncidentSeverity.low;
    }
  }

  static IncidentStatus _status(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'closed':
        return IncidentStatus.closed;
      case 'investigating':
      case 'in_review':
      case 'in-review':
      case 'under_review':
        return IncidentStatus.inReview;
      default:
        return IncidentStatus.open;
    }
  }

  static String _statusLabel(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.inReview:
        return 'Under Investigation';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  const StaffIncidentsMapper._();
}
