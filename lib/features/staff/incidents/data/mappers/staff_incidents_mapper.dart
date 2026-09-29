import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../hr/incidents/data/mappers/incidents_mapper.dart';
import '../../domain/entities/incident_activity_entry.dart';
import '../../domain/entities/incident_detail.dart';
import '../../domain/entities/incident_evidence_item.dart';
import '../../domain/entities/staff_incident.dart';
import '../../domain/entities/staff_incident_options.dart';
import '../../domain/entities/staff_incidents_enums.dart';
import '../../domain/entities/staff_incidents_summary.dart';

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
    final residence = JsonCodec.mapAt(json, 'residence') ?? {};
    final reporter = JsonCodec.mapAt(json, 'reporter') ??
        JsonCodec.mapAt(json, 'reportedBy') ??
        {};
    final categoryMap = JsonCodec.mapAt(json, 'category') ?? {};
    final name = JsonCodec.stringOr(
      client['preferredName'] ??
          client['name'] ??
          json['clientName'] ??
          json['residentName'],
      'Resident',
    );
    final reporterName = IsoDateRange.personName(
      reporter.isEmpty ? json['reportedByName'] : reporter,
    );
    final assignees = JsonCodec.listAt(json, 'assignees').isEmpty
        ? JsonCodec.listAt(json, 'assignedStaff')
        : JsonCodec.listAt(json, 'assignees');
    final occurred = JsonCodec.dateTime(
      json['occurredAt'] ?? json['createdAt'] ?? json['reportedAt'],
    );
    final reportedAt = JsonCodec.dateTime(json['reportedAt'] ?? json['createdAt']);
    final acknowledgedAt = JsonCodec.dateTime(json['acknowledgedAt']);
    final categoryLabel = JsonCodec.stringOr(
      categoryMap['name'] ??
          json['categoryName'] ??
          (json['category'] is String ? json['category'] : null),
      '',
    );

    return StaffIncident(
      id: JsonCodec.stringOr(json['id'], name),
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      categoryLabel: categoryLabel,
      residenceName: JsonCodec.stringOr(
        residence['name'] ?? json['residenceName'],
        '',
      ),
      reportedByName: reporterName == 'Unknown' ? '' : reporterName,
      reportedAtLabel: reportedAt == null
          ? ''
          : IsoDateRange.formatShortDate(reportedAt.toLocal()),
      acknowledged: acknowledgedAt != null,
      acknowledgedAtLabel: acknowledgedAt == null
          ? null
          : IsoDateRange.formatShortDate(acknowledgedAt.toLocal()),
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
    final payload = JsonCodec.mapAt(json, 'payload') ?? {};
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
        json['description'] ??
            payload['description'] ??
            payload['summary'] ??
            json['body'] ??
            json['narrative'],
        '',
      ),
      activity: activityFrom(json['activity'] ?? json['activities']),
      evidence: evidenceFrom(
        json['evidence'] ?? json['attachments'] ?? json['files'],
      ),
      cirReport: IncidentsMapper.investigationSummaryFrom(body),
    );
  }

  static List<IncidentEvidenceItem> evidenceFrom(dynamic body) {
    final items = JsonCodec.unwrapList(body);
    final out = <IncidentEvidenceItem>[];
    for (final item in items) {
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      final url = JsonCodec.string(
        row['fileUrl'] ?? row['url'] ?? row['publicUrl'],
      );
      if (url == null || url.isEmpty) continue;
      final name = JsonCodec.stringOr(
        row['fileName'] ?? row['name'],
        url.split('/').last,
      );
      out.add(
        IncidentEvidenceItem(
          fileName: name,
          fileUrl: url,
          fileType: JsonCodec.stringOr(
            row['fileType'] ?? row['mimeType'] ?? row['contentType'],
            'file',
          ),
          sizeLabel: JsonCodec.string(
            row['sizeLabel'] ?? row['size'] ?? row['fileSize'],
          ),
        ),
      );
    }
    return out;
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
      case 'resolved':
      case 'archived':
        return IncidentStatus.closed;
      case 'investigating':
      case 'in_review':
      case 'in-review':
      case 'under_review':
      case 'in review':
        return IncidentStatus.inReview;
      default:
        return IncidentStatus.open;
    }
  }

  /// UI "In Review" → API `investigating`.
  static String? statusQueryValue(IncidentStatus? status) {
    if (status == null) return null;
    return switch (status) {
      IncidentStatus.open => 'open',
      IncidentStatus.inReview => 'investigating',
      IncidentStatus.closed => 'closed',
    };
  }

  static StaffIncidentsSummary summaryFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final byStatus = JsonCodec.mapAt(json, 'byStatus') ?? {};
    final bySeverity = JsonCodec.mapAt(json, 'bySeverity') ?? {};

    final openTotal = byStatus.isEmpty
        ? JsonCodec.integerOr(
            json['open'] ?? json['openCount'] ?? json['openIncidents'],
            0,
          )
        : JsonCodec.integerOr(byStatus['open'], 0);

    final investigatingTotal = byStatus.isEmpty
        ? JsonCodec.integerOr(
            json['investigating'] ??
                json['underReview'] ??
                json['inReview'] ??
                json['pendingReview'],
            0,
          )
        : JsonCodec.integerOr(byStatus['investigating'], 0) +
            JsonCodec.integerOr(byStatus['inProgress'], 0);

    final closed = byStatus.isEmpty
        ? JsonCodec.integerOr(
            json['closed'] ?? json['closedCount'] ?? json['resolved'],
            0,
          )
        : JsonCodec.integerOr(byStatus['closed'], 0) +
            JsonCodec.integerOr(byStatus['resolved'], 0);

    final serious = JsonCodec.integerOr(
      json['serious'] ?? json['highOrCritical'],
      JsonCodec.integerOr(bySeverity['high'], 0) +
          JsonCodec.integerOr(bySeverity['critical'], 0),
    );

    final total = JsonCodec.integerOr(
      json['total'] ?? json['totalCount'] ?? json['count'],
      openTotal + investigatingTotal + closed,
    );

    return StaffIncidentsSummary(
      total: total,
      open: openTotal,
      investigating: investigatingTotal,
      closed: closed,
      serious: serious,
      awaitingInvestigation: JsonCodec.integerOr(
        json['awaitingInvestigation'],
        0,
      ),
      openInvestigations: JsonCodec.integerOr(json['openInvestigations'], 0),
      watchlist: _watchlistFrom(json['watchlist']),
      investigationQueue: _queueFrom(json['investigationQueue']),
    );
  }

  static List<StaffIncidentWatchlistItem> _watchlistFrom(dynamic raw) {
    if (raw is! List) return const [];
    final items = <StaffIncidentWatchlistItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.stringOr(json['id'], '');
      if (id.isEmpty) continue;
      final hasInvestigation =
          JsonCodec.boolean(json['hasInvestigation']) ?? false;
      final stage = hasInvestigation
          ? 'Investigation ${JsonCodec.stringOr(json['investigationStatus'] ?? json['status'], 'open')}'
          : 'Not started';
      items.add(
        StaffIncidentWatchlistItem(
          id: id,
          title: JsonCodec.stringOr(
            json['title'] ?? json['reference'],
            'Untitled incident',
          ),
          residence: JsonCodec.stringOr(json['residence'], ''),
          client: JsonCodec.stringOr(json['client'], ''),
          severityLabel: JsonCodec.stringOr(json['severity'], ''),
          stageLabel: stage,
          hasInvestigation: hasInvestigation,
          acknowledged: JsonCodec.dateTime(json['acknowledgedAt']) != null,
        ),
      );
    }
    return items;
  }

  static List<StaffIncidentQueueItem> _queueFrom(dynamic raw) {
    if (raw is! List) return const [];
    final items = <StaffIncidentQueueItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.stringOr(
        json['incidentId'] ?? json['id'],
        '',
      );
      if (id.isEmpty) continue;
      items.add(
        StaffIncidentQueueItem(
          id: id,
          caseName: JsonCodec.stringOr(
            json['title'] ?? json['reference'] ?? json['caseName'],
            'Untitled incident',
          ),
          stage: JsonCodec.stringOr(json['stage'] ?? json['status'], ''),
          investigator: JsonCodec.string(json['investigator']),
        ),
      );
    }
    return items;
  }

  static List<StaffIncidentCategoryOption> categoriesFrom(dynamic body) {
    var source = JsonCodec.unwrapList(body);
    if (source.isEmpty) {
      final map = JsonCodec.unwrapMap(body);
      final nested = map['categories'] ?? map['items'] ?? map['results'];
      if (nested is List) source = nested;
    }
    final options = <StaffIncidentCategoryOption>[];
    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ?? json['label'] ?? json['title'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        StaffIncidentCategoryOption(
          id: JsonCodec.stringOr(json['id'] ?? json['categoryId'], name),
          name: name,
        ),
      );
    }
    return options;
  }

  static List<StaffCirTemplateOption> cirTemplatesFrom(dynamic body) {
    var source = JsonCodec.unwrapList(body);
    if (source.isEmpty) {
      final map = JsonCodec.unwrapMap(body);
      final nested = map['templates'] ?? map['items'] ?? map['results'];
      if (nested is List) source = nested;
    }
    final options = <StaffCirTemplateOption>[];
    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            json['name'] ?? json['label'] ?? json['title'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        StaffCirTemplateOption(
          id: JsonCodec.stringOr(json['id'] ?? json['cirTemplateId'], name),
          name: name,
          version: JsonCodec.string(json['version']),
          sections: _cirSectionsFrom(json['fields'] ?? json['sections']),
        ),
      );
    }
    return options;
  }

  static List<StaffCirTemplateSection> _cirSectionsFrom(dynamic raw) {
    if (raw is! List) return const [];
    final sections = <StaffCirTemplateSection>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final title = JsonCodec.stringOr(
        json['title'] ?? json['label'] ?? json['name'],
        '',
      );
      if (title.isEmpty) continue;
      final fieldsRaw = json['fields'] ?? json['subFields'];
      final fields = <StaffCirTemplateField>[];
      if (fieldsRaw is List) {
        for (final fieldItem in fieldsRaw) {
          if (fieldItem is! Map) continue;
          final field = JsonCodec.asMap(fieldItem);
          final key = JsonCodec.stringOr(field['key'] ?? field['id'], '');
          final label = JsonCodec.stringOr(
            field['label'] ?? field['title'] ?? field['name'],
            '',
          );
          if (key.isEmpty || label.isEmpty) continue;
          fields.add(
            StaffCirTemplateField(
              key: key,
              label: label,
              type: JsonCodec.stringOr(field['type'], 'text'),
              required: JsonCodec.boolean(field['required']) ?? false,
              helpText: JsonCodec.stringOr(
                field['helpText'] ?? field['placeholder'],
                '',
              ),
            ),
          );
        }
      }
      sections.add(
        StaffCirTemplateSection(
          key: JsonCodec.stringOr(json['key'] ?? json['id'], title),
          title: title,
          fields: fields,
        ),
      );
    }
    return sections;
  }

  static List<StaffIncidentResidenceOption> residencesFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <StaffIncidentResidenceOption>[];
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
        StaffIncidentResidenceOption(
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

  static List<StaffIncidentClientOption> clientsFrom(dynamic body) {
    final source = JsonCodec.unwrapList(body);
    final options = <StaffIncidentClientOption>[];
    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
      final name = JsonCodec.string(
            json['preferredName'] ??
                json['fullName'] ??
                json['name'] ??
                json['displayName'] ??
                json['clientName'],
          ) ??
          '';
      if (name.isEmpty) continue;
      options.add(
        StaffIncidentClientOption(
          id: JsonCodec.stringOr(json['id'] ?? json['clientId'], name),
          name: name,
          residenceId: JsonCodec.string(
            json['residenceId'] ?? residence['id'],
          ),
          residenceName: JsonCodec.string(
            json['residenceName'] ?? residence['name'],
          ),
          roomLabel: JsonCodec.string(
            json['room'] ?? json['roomNumber'] ?? json['location'],
          ),
        ),
      );
    }
    return options;
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
