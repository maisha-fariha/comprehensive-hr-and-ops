import '../../../../../core/network/json_codec.dart';
import '../../../../../core/time/tenant_clock.dart';
import '../../domain/entities/compliance.dart';

abstract final class ComplianceMapper {
  static CompliancePageResult<T> pageFrom<T>(
    dynamic body,
    List<T> Function(dynamic body) itemsFrom, {
    int fallbackPage = 1,
    int fallbackLimit = 20,
  }) {
    final meta = JsonCodec.metaOf(body) ?? const {};
    final items = itemsFrom(body);
    final total = JsonCodec.integer(meta['total']) ?? items.length;
    final limit = JsonCodec.integer(meta['limit']) ?? fallbackLimit;
    final page = JsonCodec.integer(meta['page']) ?? fallbackPage;
    final totalPages = JsonCodec.integer(meta['totalPages']) ??
        (limit <= 0 ? 1 : ((total + limit - 1) ~/ limit).clamp(1, 999999));
    final summary = JsonCodec.asMap(meta['summary']);
    return CompliancePageResult(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages < 1 ? 1 : totalPages,
      summary: summary,
    );
  }

  static ComplianceOverview overviewFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final breakdown = <String, num>{};
    final rawBreakdown = JsonCodec.asMap(json['breakdown']);
    rawBreakdown.forEach((k, v) {
      final n = JsonCodec.number(v);
      if (n != null) breakdown[k] = n;
    });
    final domains = <ComplianceDomainScore>[
      for (final row in JsonCodec.listAt(json, 'domains'))
        if (JsonCodec.string(JsonCodec.asMap(row)['domain']) case final d?)
          ComplianceDomainScore(
            domain: d,
            percent: JsonCodec.number(JsonCodec.asMap(row)['percent'])
                    ?.toDouble() ??
                0,
          ),
    ];
    final client = JsonCodec.asMap(json['clientFiles']);
    final med = JsonCodec.asMap(json['medication']);
    final trend = <ComplianceTrendPoint>[
      for (final row in JsonCodec.listAt(json, 'trend'))
        ComplianceTrendPoint(
          weekStart: JsonCodec.dateTime(JsonCodec.asMap(row)['weekStart']),
          opened: JsonCodec.integer(JsonCodec.asMap(row)['opened']) ?? 0,
        ),
    ];
    final upcoming = <ComplianceUpcoming>[
      for (final row in JsonCodec.listAt(json, 'upcoming'))
        if (JsonCodec.string(JsonCodec.asMap(row)['id']) case final id?)
          ComplianceUpcoming(
            id: id,
            title: JsonCodec.stringOr(
              JsonCodec.asMap(row)['title'] ?? JsonCodec.asMap(row)['name'],
              'Audit',
            ),
            dueAt: JsonCodec.dateTime(JsonCodec.asMap(row)['dueAt']),
          ),
    ];
    final sources = <ComplianceSourceIssue>[
      for (final row in JsonCodec.listAt(json, 'sources'))
        ComplianceSourceIssue(
          source: JsonCodec.stringOr(
            JsonCodec.asMap(row)['source'] ?? JsonCodec.asMap(row)['module'],
            'Source',
          ),
          count: JsonCodec.integer(JsonCodec.asMap(row)['count']) ?? 0,
        ),
    ];
    return ComplianceOverview(
      score: JsonCodec.number(json['score'])?.toDouble() ?? 0,
      computedAt: JsonCodec.dateTime(json['computedAt']),
      breakdown: breakdown,
      domains: domains,
      clientFiles: ComplianceClientFiles(
        residents: JsonCodec.integer(client['residents']) ?? 0,
        missingCarePlan: JsonCodec.integer(client['missingCarePlan']) ?? 0,
        missingRoom: JsonCodec.integer(client['missingRoom']) ?? 0,
      ),
      medication: ComplianceMedication(
        missed: JsonCodec.integer(med['missed']) ?? 0,
        refused: JsonCodec.integer(med['refused']) ?? 0,
        late: JsonCodec.integer(med['late']) ?? 0,
      ),
      trend: trend,
      upcoming: upcoming,
      sources: sources,
    );
  }

  static List<ComplianceAlert> alertsFrom(dynamic body) {
    return [
      for (final row in JsonCodec.unwrapList(body))
        if (_alertFrom(row) case final a?) a,
    ];
  }

  static ComplianceAlert? _alertFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    // Live GET /compliance/alerts returns {type, severity, message, meta}.
    final id = JsonCodec.string(
      json['id'] ?? json['key'] ?? json['type'] ?? json['kind'],
    );
    final title = JsonCodec.string(
      json['message'] ??
          json['title'] ??
          json['label'] ??
          json['kind'] ??
          json['type'],
    );
    if (id == null || title == null) return null;
    return ComplianceAlert(
      id: id,
      title: title,
      kind: JsonCodec.string(json['type'] ?? json['kind']),
      severity: JsonCodec.string(json['severity']),
      detail: JsonCodec.string(json['detail'] ?? json['description']),
    );
  }

  static List<ComplianceRequirement> requirementsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (_requirementFrom(row) case final r?) r,
      ];

  static ComplianceRequirement? _requirementFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    final name = JsonCodec.string(json['name']);
    if (id == null || name == null) return null;
    return ComplianceRequirement(
      id: id,
      name: name,
      standard: JsonCodec.string(json['standard']),
      category: JsonCodec.string(json['category']),
      frequency: JsonCodec.stringOr(json['frequency'], 'quarterly'),
      frequencyNote: JsonCodec.string(json['frequencyNote']),
      priority: JsonCodec.stringOr(json['priority'], 'medium'),
      evidenceRequired: JsonCodec.boolean(json['evidenceRequired']) ?? false,
      instructions: JsonCodec.string(json['instructions']),
      isActive: JsonCodec.boolean(json['isActive']) ??
          (json['archivedAt'] == null),
      archivedAt: JsonCodec.dateTime(json['archivedAt']),
    );
  }

  static List<ComplianceCheck> checksFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (_checkFrom(row) case final c?) c,
      ];

  static ComplianceCheck? _checkFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    final requirementId = JsonCodec.string(json['requirementId']);
    final residenceId = JsonCodec.string(json['residenceId']);
    if (id == null || requirementId == null || residenceId == null) return null;
    return ComplianceCheck(
      id: id,
      requirementId: requirementId,
      requirementName: JsonCodec.string(json['requirementName']),
      standard: JsonCodec.string(json['standard']),
      priority: JsonCodec.string(json['priority']),
      evidenceRequired: JsonCodec.boolean(json['evidenceRequired']) ?? false,
      residenceId: residenceId,
      residenceName: JsonCodec.string(json['residenceName']),
      assignedStaffId: JsonCodec.string(json['assignedStaffId']),
      assignedStaffName: JsonCodec.string(json['assignedStaffName']),
      dueAt: JsonCodec.dateTime(json['dueAt']),
      checkedAt: JsonCodec.dateTime(json['checkedAt']),
      result: JsonCodec.string(json['result']),
      notes: JsonCodec.string(json['notes']),
      findingId: JsonCodec.string(json['findingId']),
      findingTitle: JsonCodec.string(json['findingTitle']),
      reviewedByName: JsonCodec.string(json['reviewedByName']),
      reviewedAt: JsonCodec.dateTime(json['reviewedAt']),
    );
  }

  static List<ComplianceFinding> findingsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (_findingFrom(row) case final f?) f,
      ];

  static ComplianceFinding? _findingFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    final title = JsonCodec.string(json['title']);
    if (id == null || title == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final client = JsonCodec.mapAt(json, 'client') ?? const {};
    final clientName = () {
      final first = JsonCodec.stringOr(client['firstName'], '');
      final last = JsonCodec.stringOr(client['lastName'], '');
      final joined = '$first $last'.trim();
      return joined.isEmpty ? JsonCodec.string(json['clientName']) : joined;
    }();
    return ComplianceFinding(
      id: id,
      title: title,
      residenceId: JsonCodec.string(json['residenceId'] ?? residence['id']),
      residenceName: JsonCodec.string(
        json['residenceName'] ?? residence['name'],
      ),
      clientId: JsonCodec.string(json['clientId'] ?? client['id']),
      clientName: clientName,
      severity: JsonCodec.string(json['severity']),
      status: JsonCodec.string(json['status']),
      framework: JsonCodec.string(json['framework']),
      issueOrigin: JsonCodec.string(json['issueOrigin']),
      riskContext: JsonCodec.string(json['riskContext']),
      notes: JsonCodec.string(json['notes'] ?? json['description']),
      sourceRecordType: JsonCodec.string(json['sourceRecordType']),
      sourceRecordId: JsonCodec.string(json['sourceRecordId']),
      dueAt: JsonCodec.dateTime(json['dueAt']),
      resolvedAt: JsonCodec.dateTime(json['resolvedAt']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      assigneeName: JsonCodec.string(json['assigneeName'] ?? json['ownerName']),
    );
  }

  static List<ComplianceAction> actionsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (_actionFrom(row) case final a?) a,
      ];

  static ComplianceAction? _actionFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    final description = JsonCodec.string(json['description']);
    if (id == null || description == null) return null;
    final owner = JsonCodec.mapAt(json, 'owner') ?? const {};
    final ownerName = () {
      final first = JsonCodec.stringOr(owner['firstName'], '');
      final last = JsonCodec.stringOr(owner['lastName'], '');
      final joined = '$first $last'.trim();
      return joined.isEmpty
          ? JsonCodec.string(json['ownerName'] ?? json['assignedToName'])
          : joined;
    }();
    return ComplianceAction(
      id: id,
      description: description,
      incidentId: JsonCodec.string(json['incidentId'] ?? json['findingId']),
      findingTitle: JsonCodec.string(json['findingTitle'] ?? json['title']),
      ownerId: JsonCodec.string(json['ownerId'] ?? owner['id']),
      ownerName: ownerName,
      status: JsonCodec.string(json['status']),
      dueAt: JsonCodec.dateTime(json['dueAt']),
      verifiedAt: JsonCodec.dateTime(json['verifiedAt'] ?? json['signedOffAt']),
      verifiedByName: JsonCodec.string(json['verifiedByName']),
    );
  }

  static List<ComplianceAuditLog> auditLogsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (_auditFrom(row) case final a?) a,
      ];

  static ComplianceAuditLog? _auditFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    final action = JsonCodec.string(json['action']);
    if (id == null || action == null) return null;
    return ComplianceAuditLog(
      id: id,
      action: action,
      actorName: JsonCodec.string(json['actorName']) ?? 'System',
      module: JsonCodec.string(json['module']),
      entityType: JsonCodec.string(json['entityType']),
      entityId: JsonCodec.string(json['entityId']),
      outcome: JsonCodec.string(json['outcome']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static List<CompliancePersonOption> peopleFrom(dynamic body) {
    return [
      for (final row in JsonCodec.unwrapList(body))
        if (_personFrom(row) case final p?) p,
    ];
  }

  static CompliancePersonOption? _personFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final name = JsonCodec.string(json['name']);
    if (name != null && name.isNotEmpty) {
      return CompliancePersonOption(id: id, name: name);
    }
    final first = JsonCodec.stringOr(json['firstName'], '');
    final last = JsonCodec.stringOr(json['lastName'], '');
    final joined = '$first $last'.trim();
    if (joined.isEmpty) return null;
    return CompliancePersonOption(id: id, name: joined);
  }

  static ComplianceExportJob? exportFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return ComplianceExportJob(
      id: id,
      reportKey: JsonCodec.stringOr(json['reportKey'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      downloadUrl: JsonCodec.string(
        json['downloadUrl'] ?? json['fileUrl'],
      ),
    );
  }

  static List<ComplianceExportJob> exportsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body))
          if (exportFrom(row) case final j?) j,
      ];

  static const frequencies = [
    ('one_time', 'One-off'),
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('quarterly', 'Quarterly'),
  ];

  static const priorities = [
    ('low', 'Low'),
    ('medium', 'Medium'),
    ('high', 'High'),
    ('critical', 'Critical'),
  ];

  static const severities = [
    ('low', 'Low', 'Minor, no resident affected'),
    ('medium', 'Medium', 'A gap in process — watch it'),
    ('high', 'High', 'A resident is at risk — act now'),
    ('critical', 'Critical', 'Escalate immediately'),
  ];

  static const issueOrigins = [
    ('internal_audit', 'Internal audit'),
    ('compliance_check', 'A compliance check'),
    ('automated_alert', 'An automated alert'),
    ('staff_report', 'Reported by staff'),
    ('regulatory_inspection', 'Regulatory inspection'),
  ];

  /// Web Checks → Carry out result options.
  static const checkResults = [
    ('compliant', 'Compliant'),
    ('partially_compliant', 'Partially compliant'),
    ('non_compliant', 'Not compliant'),
    ('needs_review', 'Needs review'),
  ];

  static const raiseFindingResults = {
    'non_compliant',
    'partially_compliant',
  };

  static const pageSizes = [10, 20, 25, 50];

  static String label(String raw) {
    if (raw.isEmpty) return '—';
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String when(DateTime? at) => TenantClock.formatDateTime(at);

  static String readinessTone(num score) {
    if (score >= 90) return 'Ready';
    if (score >= 70) return 'Watch';
    return 'At risk';
  }
}
