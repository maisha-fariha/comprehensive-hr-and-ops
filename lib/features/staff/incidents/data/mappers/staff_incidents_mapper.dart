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
    final payload = Map<String, dynamic>.from(
      JsonCodec.mapAt(json, 'payload') ??
          JsonCodec.mapAt(json, 'payloadJson') ??
          const {},
    );
    _ensurePartiesNotifiedMap(payload);

    final bodyForCir = Map<String, dynamic>.from(json);
    bodyForCir['payload'] = payload;
    final cirReport = IncidentsMapper.investigationSummaryFrom(bodyForCir);

    final reporterName = IsoDateRange.personName(
      reporter.isEmpty ? json['reportedByName'] : reporter,
    );
    final shortId = list.id.length > 8 ? list.id.substring(0, 8) : list.id;
    final shortIdLabel = '#$shortId';

    final residenceName = _preferNonEmpty(
      list.residenceName,
      _dashToEmpty(cirReport.residenceName),
    );
    final residentName = _preferNonEmpty(
      list.personName == 'Resident' ? '' : list.personName,
      _dashToEmpty(cirReport.clientName),
      fallback: list.personName,
    );
    final reportedByResolved = _preferNonEmpty(
      reporterName == 'Unknown' ? '' : reporterName,
      _dashToEmpty(cirReport.reportedByName),
      fallback: reporterName,
    );

    final reportedAt = JsonCodec.dateTime(
      json['reportedAt'] ?? json['createdAt'],
    );
    final reportedAtLabel = reportedAt == null
        ? _preferNonEmpty(
            list.reportedAtLabel,
            _dashToEmpty(cirReport.reportedAtLabel),
          )
        : IsoDateRange.formatShortDate(reportedAt.toLocal());

    final acknowledgedAt = JsonCodec.dateTime(json['acknowledgedAt']);
    final investigation = JsonCodec.mapAt(json, 'investigation') ?? const {};
    final investigationRecordedAt = JsonCodec.dateTime(
      investigation['updatedAt'] ??
          investigation['recordedAt'] ??
          payload['updatedAt'] ??
          payload['investigationUpdatedAt'],
    );
    final recordedByRaw = investigation['recordedBy'] ??
        investigation['investigator'] ??
        payload['recordedBy'] ??
        payload['investigationRecordedBy'];
    final recordedByName = recordedByRaw == null
        ? null
        : IsoDateRange.personName(recordedByRaw);

    return IncidentDetail(
      id: list.id,
      incidentCode: JsonCodec.stringOr(
        json['code'] ?? json['incidentCode'] ?? json['cirNumber'],
        list.id,
      ),
      categoryLabel: JsonCodec.stringOr(
        JsonCodec.mapAt(json, 'category')?['name'] ??
            json['categoryName'] ??
            (json['category'] is String ? json['category'] : null),
        'Incident',
      ),
      title: list.title,
      iconKind: list.iconKind,
      dateTimeLabel: list.dateTimeLabel,
      severity: list.severity,
      statusLabel: _statusLabel(list.status),
      detectedDuring: JsonCodec.stringOr(
        json['detectedDuring'] ??
            payload['detectedDuring'] ??
            json['shift'] ??
            json['context'],
        '',
      ),
      location: JsonCodec.stringOr(
        json['location'] ??
            payload['incidentLocationDescription'] ??
            payload['location'] ??
            json['room'],
        '',
      ),
      residentName: residentName,
      residentSubLabel: JsonCodec.stringOr(
        client['room'] ?? client['roomNumber'] ?? json['room'],
        '',
      ),
      residentInitials: IsoDateRange.initials(residentName),
      reportedByName: reportedByResolved,
      reportedBySubLabel: JsonCodec.stringOr(
        reporter['role'] ?? reporter['title'] ?? json['reportedByRole'],
        '',
      ),
      reportedByInitials: IsoDateRange.initials(reportedByResolved),
      // Top DESCRIPTION matches web: only freeform description fields — not
      // CIR `incidentDescription` (that lives inside the Report form section).
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
      cirReport: cirReport,
      shortIdLabel: shortIdLabel,
      residenceName: residenceName,
      reportedAtLabel: reportedAtLabel,
      acknowledged: acknowledgedAt != null || list.acknowledged,
      acknowledgedAtLabel: acknowledgedAt == null
          ? list.acknowledgedAtLabel
          : IsoDateRange.formatShortDate(acknowledgedAt.toLocal()),
      witnessNames: _witnessNames(payload['witnesses'] ?? json['witnesses']),
      investigationStatus: _humanizeToken(
        investigation['status'] ?? payload['investigationStatus'],
      ),
      investigationFindings: JsonCodec.string(
        investigation['findings'] ??
            payload['findings'] ??
            payload['investigationFindings'] ??
            payload['investigationNotes'],
      ),
      investigationRootCause: JsonCodec.string(
        investigation['rootCause'] ?? payload['rootCause'],
      ),
      investigationCorrectiveAction: JsonCodec.string(
        investigation['correctiveActions'] ??
            investigation['correctiveAction'] ??
            payload['correctiveActions'] ??
            payload['correctiveAction'],
      ),
      investigationRecordedBy:
          recordedByName == null || recordedByName == 'Unknown'
              ? null
              : recordedByName,
      investigationRecordedAtLabel: investigationRecordedAt == null
          ? null
          : IsoDateRange.formatShortDate(investigationRecordedAt.toLocal()),
    );
  }

  /// When payload has a `notifications` list but no `partiesNotified` map,
  /// build the map CIR display expects (keyed by simplified party slugs).
  static void _ensurePartiesNotifiedMap(Map<String, dynamic> payload) {
    if (payload['partiesNotified'] is Map) return;
    final notifications = payload['notifications'];
    if (notifications is! List) return;
    final map = <String, Map<String, dynamic>>{};
    for (final item in notifications) {
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      final party = JsonCodec.stringOr(row['party'] ?? row['label'], '');
      if (party.isEmpty) continue;
      final key = _partySlug(party);
      map[key] = {
        'notified': row['notified'] == true ||
            row['notified'] == 'yes' ||
            row['notified'] == 'Yes',
        if (JsonCodec.string(row['contactName']) != null)
          'contactName': JsonCodec.string(row['contactName']),
        if (JsonCodec.string(row['dateNotified']) != null)
          'dateNotified': JsonCodec.string(row['dateNotified']),
      };
    }
    if (map.isNotEmpty) {
      payload['partiesNotified'] = map;
    }
  }

  static String _partySlug(String party) {
    return party
        .trim()
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static List<String> _witnessNames(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final item in raw) {
      if (item is String) {
        final name = item.trim();
        if (name.isNotEmpty) out.add(name);
        continue;
      }
      if (item is! Map) continue;
      final row = JsonCodec.asMap(item);
      final name = JsonCodec.string(
            row['name'] ?? row['fullName'] ?? row['witness'] ?? row['label'],
          ) ??
          '';
      if (name.trim().isNotEmpty) out.add(name.trim());
    }
    return out;
  }

  static String _dashToEmpty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '—' || trimmed == '-') return '';
    return trimmed;
  }

  static String _preferNonEmpty(
    String primary,
    String secondary, {
    String fallback = '',
  }) {
    if (primary.trim().isNotEmpty) return primary.trim();
    if (secondary.trim().isNotEmpty) return secondary.trim();
    return fallback;
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
      final fileType = JsonCodec.stringOr(
        row['fileType'] ?? row['mimeType'] ?? row['contentType'],
        'file',
      );
      // Web shows mime type when fileName is null.
      final named = JsonCodec.string(row['fileName'] ?? row['name']);
      final name = (named != null && named.isNotEmpty)
          ? named
          : (fileType != 'file' ? fileType : url.split('/').last);
      final uploadedAt = JsonCodec.dateTime(
        row['createdAt'] ?? row['uploadedAt'],
      );
      final uploader = row['uploader'] ?? row['uploadedBy'];
      final uploaderName = uploader == null
          ? null
          : IsoDateRange.personName(uploader);
      out.add(
        IncidentEvidenceItem(
          fileName: name,
          fileUrl: url,
          fileType: fileType,
          sizeLabel: JsonCodec.string(
            row['sizeLabel'] ?? row['size'] ?? row['fileSize'],
          ),
          uploadedByName:
              uploaderName == null || uploaderName == 'Unknown'
                  ? null
                  : uploaderName,
          uploadedAtLabel: uploadedAt == null
              ? null
              : IsoDateRange.formatShortDate(uploadedAt.toLocal()),
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
    final outcome =
        (JsonCodec.string(json['outcome']) ?? '').trim().toLowerCase();
    final isFailure = outcome == 'failure' || outcome == 'failed' || outcome == 'error';
    return IncidentActivityEntry(
      title: _activityTitle(json),
      meta: [
        if (actor != 'Unknown') actor,
        if (at != null) IsoDateRange.formatShortDate(at.toLocal()),
      ].join(' · '),
      isActive: isActive,
      isFailure: isFailure,
    );
  }

  /// Maps API audit actions to web labels
  /// (e.g. `incidents.acknowledge.create` → `Acknowledged`).
  static String _activityTitle(Map<String, dynamic> json) {
    final explicit = JsonCodec.string(json['title']);
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final raw = (JsonCodec.string(
              json['action'] ?? json['type'] ?? json['event'],
            ) ??
            '')
        .trim()
        .toLowerCase();
    if (raw.contains('acknowledge')) return 'Acknowledged';
    if (raw.contains('investigation')) return 'Investigation updated';
    if (raw == 'incidents.update' ||
        raw.endsWith('.update') ||
        raw.contains('details')) {
      return 'Details updated';
    }
    if (raw.contains('create') || raw.contains('report')) {
      return 'Incident reported';
    }
    if (raw.isEmpty) return 'Update';
    return _humanizeToken(raw.replaceAll('.', ' ')) ?? 'Update';
  }

  static String? _humanizeToken(dynamic raw) {
    final value = (JsonCodec.string(raw) ?? '').trim();
    if (value.isEmpty) return null;
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
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
      final first = JsonCodec.stringOr(json['firstName'], '');
      final last = JsonCodec.stringOr(json['lastName'], '');
      final composed = '$first $last'.trim();
      final name = JsonCodec.string(
            json['preferredName'] ??
                json['fullName'] ??
                json['name'] ??
                json['displayName'] ??
                json['clientName'] ??
                (composed.isEmpty ? null : composed),
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
        return 'Investigating';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  const StaffIncidentsMapper._();
}
