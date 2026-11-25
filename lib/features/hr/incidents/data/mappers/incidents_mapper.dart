import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/closed_incident.dart';
import '../../domain/entities/incident_ai_draft.dart';
import '../../domain/entities/incident_category_option.dart';
import '../../domain/entities/incident_cir_template_option.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_investigation_summary.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incident_witness_statement.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/entities/open_incident.dart';
import '../cir_answer_formatter.dart';

abstract final class IncidentsMapper {
  /// Parse `GET /incidents/:id/witness-statements`.
  static List<IncidentWitnessStatement> witnessStatementsFrom(dynamic body) {
    final statements = <IncidentWitnessStatement>[];
    for (final item in JsonCodec.unwrapList(body)) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final takenBy = JsonCodec.mapAt(json, 'takenBy');
      final takenByName = takenBy == null
          ? null
          : '${JsonCodec.stringOr(takenBy['firstName'], '')} '
                  '${JsonCodec.stringOr(takenBy['lastName'], '')}'
              .trim();
      statements.add(
        IncidentWitnessStatement(
          id: id,
          witnessType: JsonCodec.stringOr(json['witnessType'], 'staff'),
          witnessName: JsonCodec.stringOr(json['witnessName'], ''),
          statementText: JsonCodec.stringOr(json['statementText'], ''),
          takenByName: takenByName,
          signedAt: () {
            final at = JsonCodec.dateTime(json['signedAt']);
            return at == null ? null : TenantClock.wallOf(at);
          }(),
        ),
      );
    }
    return statements;
  }

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
      final fullName = [json['firstName'], json['lastName']]
          .map((part) => JsonCodec.string(part)?.trim() ?? '')
          .where((part) => part.isNotEmpty)
          .join(' ');
      final name = fullName.isNotEmpty
          ? fullName
          : JsonCodec.string(
                json['preferredName'] ??
                    json['fullName'] ??
                    json['name'] ??
                    json['displayName'] ??
                    json['clientName'] ??
                    json['residentName'],
              ) ??
              '';
      if (name.isEmpty) continue;

      final residenceName = JsonCodec.string(
        json['residenceName'] ?? residence['name'],
      )?.trim();
      final subtitle = [
        'Client',
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
          subtitle: subtitle,
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

  /// Parse `GET /incidents/cir-templates`.
  static List<IncidentCirTemplateOption> cirTemplatesFrom(dynamic body) {
    var source = JsonCodec.unwrapList(body);
    if (source.isEmpty) {
      final map = JsonCodec.unwrapMap(body);
      final nested = map['templates'] ?? map['items'] ?? map['results'];
      if (nested is List) source = nested;
    }
    final options = <IncidentCirTemplateOption>[];
    for (final item in source) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final name = JsonCodec.string(json['name'] ?? json['title']) ?? '';
      if (name.isEmpty) continue;
      options.add(
        IncidentCirTemplateOption(
          id: JsonCodec.stringOr(json['id'] ?? json['cirTemplateId'], name),
          name: name,
          provinceOrState: JsonCodec.string(json['provinceOrState']),
          version: JsonCodec.integer(json['version']),
          sections: _cirTemplateSectionsFrom(json['fields'] ?? json['sections']),
        ),
      );
    }
    return options;
  }

  static List<IncidentCirTemplateSection> _cirTemplateSectionsFrom(dynamic raw) {
    if (raw is! List) return const [];
    final sections = <IncidentCirTemplateSection>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final title = JsonCodec.stringOr(
        json['title'] ?? json['label'] ?? json['name'],
        '',
      );
      if (title.isEmpty) continue;
      final fieldsRaw = json['fields'] ?? json['subFields'];
      final fields = <IncidentCirTemplateField>[];
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
            IncidentCirTemplateField(
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
        IncidentCirTemplateSection(
          key: JsonCodec.stringOr(json['key'] ?? json['id'], title),
          title: title,
          fields: fields,
        ),
      );
    }
    return sections;
  }

  /// Parse `GET /staff` into people-picker options.
  static List<IncidentStaffOption> staffFrom(dynamic body) {
    final options = <IncidentStaffOption>[];
    for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
      final json = JsonCodec.asMap(item);
      final first = JsonCodec.string(json['firstName']) ?? '';
      final last = JsonCodec.string(json['lastName']) ?? '';
      final combined = '$first $last'.trim();
      final name = JsonCodec.string(
            json['name'] ??
                json['displayName'] ??
                json['fullName'] ??
                (combined.isEmpty ? null : combined),
          ) ??
          '';
      if (name.isEmpty) continue;
      final category = JsonCodec.mapAt(json, 'category') ?? const {};
      options.add(
        IncidentStaffOption(
          id: JsonCodec.stringOr(json['id'] ?? json['staffId'], name),
          name: name,
          email: JsonCodec.string(json['email']),
          roleLabel: JsonCodec.string(
            category['name'] ??
                json['categoryName'] ??
                json['role'] ??
                json['jobTitle'],
          ) ??
              'Staff',
        ),
      );
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
    final now = TenantClock.now();
    return closedRows.where((row) {
      final closedAt = JsonCodec.dateTime(
        row['closedAt'] ?? row['resolvedAt'] ?? row['updatedAt'],
      );
      if (closedAt == null) return false;
      final wall = TenantClock.wallOf(closedAt);
      return wall.year == now.year &&
          wall.month == now.month &&
          wall.day == now.day;
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
      statusLabel: _listStatusLabel(json),
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
      statusLabel: _listStatusLabel(json),
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
      dateLabel: at == null
          ? ''
          : IsoDateRange.formatShortDate(TenantClock.wallOf(at)),
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

  /// Parse `GET /incidents/:id` into the View Investigation summary sheet.
  static IncidentInvestigationSummary investigationSummaryFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final id = JsonCodec.stringOr(json['id'], 'incident');
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    final client = _clientName(json);
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final residenceName = JsonCodec.string(
          json['residenceName'] ?? residence['name'],
        ) ??
        '';
    final reportedAt = JsonCodec.dateTime(
      json['reportedAt'] ?? json['createdAt'],
    );
    final payload = Map<String, dynamic>.from(
      JsonCodec.mapAt(json, 'payload') ??
          JsonCodec.mapAt(json, 'payloadJson') ??
          const {},
    );
    final snapshotRaw = json['templateSnapshotJson'] ??
        json['templateSnapshot'] ??
        json['cirSnapshot'];
    final snapshot = snapshotRaw is Map
        ? Map<String, dynamic>.from(JsonCodec.asMap(snapshotRaw))
        : null;
    final description = JsonCodec.string(
          json['description'] ??
              payload['summary'] ??
              payload['description'] ??
              payload['incidentDescription'] ??
              json['body'] ??
              json['narrative'],
        ) ??
        '';
    final statusRaw = (JsonCodec.string(json['status']) ?? '').trim();
    final severity = _severity(json['severity']);

    return IncidentInvestigationSummary(
      id: id,
      title: JsonCodec.stringOr(json['title'] ?? json['category'], 'Incident'),
      shortIdLabel: '#$shortId',
      clientName: client.isEmpty ? '—' : client,
      residenceName: residenceName.isEmpty ? '—' : residenceName,
      reportedAtLabel: reportedAt == null
          ? '—'
          : TenantClock.formatDate(reportedAt),
      reportedAtUtcLabel:
          reportedAt == null ? '-' : _formatUtcStamp(reportedAt.toUtc()),
      reportedByName: () {
        final name = _reporterName(json);
        return name.isEmpty || name == 'Unknown' ? '—' : name;
      }(),
      description: description.trim().isEmpty
          ? 'No description recorded.'
          : description.trim(),
      statusLabel: _displayStatus(statusRaw),
      statusRaw: statusRaw.isEmpty ? '-' : statusRaw,
      severityLabel: _severityLabel(json['severity'], severity),
      iconKind: _icon(json),
      formSections: _cirFormSections(json, payload: payload),
      cirPayload: payload,
      templateSnapshot: snapshot,
    );
  }

  static String _displayStatus(dynamic raw) {
    final value = (JsonCodec.string(raw) ?? '').trim();
    if (value.isEmpty) return 'Under Review';
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

  /// Web Status column: "Open / Unacknowledged", "Closed / Ack dd/mm/yyyy".
  static String _listStatusLabel(Map<String, dynamic> json) {
    final investigation = JsonCodec.mapAt(json, 'investigation') ?? const {};
    final raw = (JsonCodec.string(
              investigation['status'] ?? json['status'],
            ) ??
            'open')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
    final base = raw.contains('investigat')
        ? 'Investigating'
        : raw.contains('close') || raw.contains('resolv')
            ? 'Closed'
            : raw.contains('under')
                ? 'Under Review'
                : _displayStatus(raw);

    final acknowledged = json['acknowledged'] == true ||
        json['acknowledgedAt'] != null ||
        JsonCodec.mapAt(json, 'acknowledgedBy') != null;
    final ackAt = JsonCodec.dateTime(json['acknowledgedAt']);
    if (base == 'Closed' || raw.contains('close') || raw.contains('resolv')) {
      if (ackAt != null) {
        return 'Closed / Ack ${TenantClock.formatDate(ackAt)}';
      }
      return acknowledged ? 'Closed / Ack' : 'Closed';
    }
    if (!acknowledged) return '$base / Unacknowledged';
    if (ackAt != null) return '$base / Ack ${TenantClock.formatDate(ackAt)}';
    return '$base / Acknowledged';
  }

  static String _formatUtcStamp(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm UTC';
  }

  static String _severityLabel(dynamic raw, IncidentSeverity severity) {
    final value = (JsonCodec.string(raw) ?? '').trim();
    if (value.isEmpty) return '-';
    switch (severity) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  static List<CirFormSection> _cirFormSections(
    Map<String, dynamic> json, {
    required Map<String, dynamic> payload,
  }) {
    final snapshot = json['templateSnapshotJson'] ??
        json['templateSnapshot'] ??
        json['cirSnapshot'];
    if (snapshot is! Map) {
      return const [
        CirFormSection(
          title: "Section 1: Child or Youth's Information",
          fields: [],
        ),
      ];
    }
    final map = JsonCodec.asMap(snapshot);
    final fieldsRaw = map['fields'] ?? map['sections'];
    if (fieldsRaw is! List || fieldsRaw.isEmpty) {
      return [
        CirFormSection(
          title: JsonCodec.stringOr(
            map['name'] ?? map['title'],
            "Section 1: Child or Youth's Information",
          ),
          fields: const [],
        ),
      ];
    }

    // Prefer explicit sections if present.
    if (fieldsRaw.first is Map &&
        (JsonCodec.asMap(fieldsRaw.first as Map).containsKey('fields') ||
            JsonCodec.asMap(fieldsRaw.first as Map).containsKey('items'))) {
      final sections = <CirFormSection>[];
      for (var i = 0; i < fieldsRaw.length; i++) {
        final item = fieldsRaw[i];
        if (item is! Map) continue;
        final section = JsonCodec.asMap(item);
        final nested = section['fields'] ?? section['items'];
        sections.add(
          CirFormSection(
            title: JsonCodec.stringOr(
              section['title'] ?? section['name'] ?? section['label'],
              'Section ${i + 1}',
            ),
            fields: _cirFields(nested, payload: payload),
          ),
        );
      }
      return sections.isEmpty
          ? [
              const CirFormSection(
                title: "Section 1: Child or Youth's Information",
              ),
            ]
          : sections;
    }

    return [
      CirFormSection(
        title: JsonCodec.stringOr(
          map['name'] ?? map['title'],
          "Section 1: Child or Youth's Information",
        ),
        fields: _cirFields(fieldsRaw, payload: payload),
      ),
    ];
  }

  static List<CirFormField> _cirFields(
    dynamic raw, {
    required Map<String, dynamic> payload,
  }) {
    if (raw is! List) return const [];
    final fields = <CirFormField>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = JsonCodec.asMap(item);
      final label = JsonCodec.string(
            json['label'] ?? json['name'] ?? json['title'] ?? json['key'],
          ) ??
          '';
      if (label.isEmpty) continue;
      final key = JsonCodec.string(json['key']) ?? '';
      final type = JsonCodec.string(json['type']) ?? 'text';
      final options = json['options'] is List ? json['options'] as List : null;

      if (type == 'table' && key == 'partiesNotified') {
        fields.addAll(_partiesNotifiedFields(payload, json));
        continue;
      }

      final rawValue = key.isNotEmpty
          ? (payload.containsKey(key) ? payload[key] : json['value'])
          : (json['value'] ??
              json['answer'] ??
              json['response'] ??
              json['defaultValue']);

      final value = CirAnswerFormatter.display(
        rawValue,
        type: type,
        options: options,
      );

      // Hide empty "Please specify" companions.
      if (label.toLowerCase().contains('please specify') &&
          value == CirAnswerFormatter.empty) {
        continue;
      }

      fields.add(CirFormField(label: label, value: value));
    }
    return fields;
  }

  static List<CirFormField> _partiesNotifiedFields(
    Map<String, dynamic> payload,
    Map<String, dynamic> fieldDef,
  ) {
    final rows = fieldDef['rows'];
    final parties = CirAnswerFormatter.partiesTable(payload);
    final out = <CirFormField>[];
    if (rows is! List) return out;

    for (final row in rows) {
      if (row is! Map) continue;
      final rowMap = JsonCodec.asMap(row);
      final rowKey = JsonCodec.string(rowMap['key']) ?? '';
      final rowLabel = JsonCodec.string(rowMap['label']) ?? rowKey;
      if (rowKey.isEmpty) continue;
      final answer = parties[rowKey] ?? const <String, dynamic>{};
      final notified = CirAnswerFormatter.display(
        answer['notified'],
        options: const [
          {'value': 'yes', 'label': 'Yes'},
          {'value': 'no', 'label': 'No'},
        ],
      );
      final contact = CirAnswerFormatter.display(answer['contactName']);
      final date = CirAnswerFormatter.display(answer['dateNotified']);
      out.add(
        CirFormField(
          label: rowLabel,
          value: '$notified · $contact · $date',
        ),
      );
    }

    final other = CirAnswerFormatter.fromPayload(
      key: 'partiesNotifiedOtherDescription',
      payload: payload,
    );
    out.add(
      CirFormField(label: 'Other, please describe', value: other),
    );
    return out;
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

  /// Parse `POST /ai/incidents/draft` (web "Draft from my notes").
  static IncidentAiDraft aiDraftFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final agencyRaw = JsonCodec.mapAt(json, 'externalAgency');
    final reportedByRaw = JsonCodec.mapAt(json, 'reportedBy');
    final supervisorRaw = JsonCodec.mapAt(json, 'supervisor');
    final childRaw = JsonCodec.mapAt(json, 'child');
    final followUpRaw = JsonCodec.mapAt(json, 'followUp');
    final debriefRaw = JsonCodec.mapAt(json, 'debrief');

    final witnesses = <String>[];
    final witnessesRaw = json['witnesses'];
    if (witnessesRaw is List) {
      for (final item in witnessesRaw) {
        final value = JsonCodec.string(item)?.trim() ?? item.toString().trim();
        if (value.isNotEmpty) witnesses.add(value);
      }
    }

    final notifications = <IncidentAiNotification>[];
    final notificationsRaw = json['notifications'];
    if (notificationsRaw is List) {
      for (final item in notificationsRaw) {
        if (item is! Map) continue;
        final map = JsonCodec.asMap(item);
        final party = JsonCodec.string(map['party'])?.trim();
        if (party == null || party.isEmpty) continue;
        notifications.add(
          IncidentAiNotification(
            party: party,
            contactName: JsonCodec.string(map['contactName']),
            date: JsonCodec.string(map['date']),
          ),
        );
      }
    }

    final missing = <String>[];
    final missingRaw = json['missing'];
    if (missingRaw is List) {
      for (final item in missingRaw) {
        final value = JsonCodec.string(item)?.trim() ?? item.toString().trim();
        if (value.isNotEmpty) missing.add(value);
      }
    }

    final cirRaw = json['cirAnswers'];
    final cirAnswers = <String, dynamic>{};
    if (cirRaw is Map) {
      cirAnswers.addAll(JsonCodec.asMap(cirRaw));
    }

    IncidentAiPerson? person(Map<String, dynamic>? raw) {
      if (raw == null) return null;
      final id = JsonCodec.string(raw['id'])?.trim();
      final name = JsonCodec.string(raw['name'])?.trim();
      if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
      return IncidentAiPerson(id: id, name: name);
    }

    return IncidentAiDraft(
      date: JsonCodec.string(json['date']),
      time: JsonCodec.string(json['time']),
      endTime: JsonCodec.string(json['endTime']),
      categoryId: JsonCodec.string(json['categoryId']),
      clientId: JsonCodec.string(json['clientId']),
      residenceId: JsonCodec.string(json['residenceId']),
      detectedDuring: JsonCodec.string(json['detectedDuring']),
      witnesses: witnesses,
      externalAgency: agencyRaw == null
          ? null
          : IncidentAiExternalAgency(
              type: JsonCodec.stringOr(agencyRaw['type'], ''),
              reference: JsonCodec.string(agencyRaw['reference']),
              responder: JsonCodec.string(agencyRaw['responder']),
            ),
      notifications: notifications,
      title: JsonCodec.stringOr(json['title'], ''),
      description: JsonCodec.stringOr(json['description'], ''),
      immediateAction: JsonCodec.stringOr(json['immediateAction'], ''),
      severity: JsonCodec.string(json['severity'])?.toLowerCase(),
      emergencyServicesContacted: json['emergencyServicesContacted'] is bool
          ? json['emergencyServicesContacted'] as bool
          : null,
      familyNotified: json['familyNotified'] is bool
          ? json['familyNotified'] as bool
          : null,
      categoryDetail: JsonCodec.string(json['categoryDetail']),
      reportedBy: person(reportedByRaw),
      supervisor: person(supervisorRaw),
      child: childRaw == null
          ? null
          : IncidentAiChild(
              idNumber: JsonCodec.string(childRaw['idNumber']),
              cfsStatus: [
                for (final item in (childRaw['cfsStatus'] is List
                    ? childRaw['cfsStatus'] as List
                    : const []))
                  if ((JsonCodec.string(item) ?? item.toString())
                      .trim()
                      .isNotEmpty)
                    (JsonCodec.string(item) ?? item.toString()).trim(),
              ],
              cipName: JsonCodec.string(childRaw['cipName']),
              cipOffice: JsonCodec.string(childRaw['cipOffice']),
              informedOfRights: childRaw['informedOfRights'] is bool
                  ? childRaw['informedOfRights'] as bool
                  : null,
            ),
      followUp: followUpRaw == null
          ? null
          : IncidentAiFollowUp(
              required: followUpRaw['required'] is bool
                  ? followUpRaw['required'] as bool
                  : null,
              dueDate: JsonCodec.string(followUpRaw['dueDate']),
            ),
      debrief: debriefRaw == null
          ? null
          : IncidentAiDebrief(
              completed: debriefRaw['completed'] is bool
                  ? debriefRaw['completed'] as bool
                  : null,
              details: JsonCodec.string(debriefRaw['details']),
            ),
      missing: missing,
      cirAnswers: cirAnswers,
      model: JsonCodec.string(json['model']),
    );
  }

  const IncidentsMapper._();
}

enum _Bucket { open, review, closed }
