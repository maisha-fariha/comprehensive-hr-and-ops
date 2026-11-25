import 'package:comprehensive_hr_and_ops/features/hr/compliance/data/mappers/compliance_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pageFrom reads meta totals and checks summary', () {
    final page = ComplianceMapper.pageFrom(
      {
        'data': [
          {
            'id': 'c1',
            'requirementId': 'r1',
            'requirementName': 'Fire door inspection',
            'residenceId': 'h1',
            'residenceName': 'Cozzy Cottege',
            'dueAt': '2026-11-10T00:00:00.000Z',
            'result': 'fail',
            'findingId': 'f1',
            'findingTitle': 'Door 12 not closing',
          },
          {'id': 'bad'},
        ],
        'meta': {
          'page': 2,
          'limit': 20,
          'total': 21,
          'totalPages': 2,
          'summary': {'outstanding': 3, 'overdue': 1},
        },
      },
      ComplianceMapper.checksFrom,
    );

    expect(page.items, hasLength(1));
    expect(page.page, 2);
    expect(page.total, 21);
    expect(page.totalPages, 2);
    expect(page.summary['outstanding'], 3);
    final check = page.items.single;
    expect(check.requirementName, 'Fire door inspection');
    expect(check.result, 'fail');
    expect(check.findingTitle, 'Door 12 not closing');
  });

  test('pageFrom keeps totalPages at least 1 for empty lists', () {
    final page = ComplianceMapper.pageFrom(
      {
        'data': <dynamic>[],
        'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
      },
      ComplianceMapper.findingsFrom,
    );
    expect(page.items, isEmpty);
    expect(page.totalPages, 1);
  });

  test('overviewFrom maps score, breakdown, domains and client files', () {
    final o = ComplianceMapper.overviewFrom({
      'data': {
        'score': 82,
        'computedAt': '2026-11-02T01:19:00.000Z',
        'breakdown': {
          'expiredDocuments': 0,
          'expiringCertificates': 1,
          'incompleteTraining': 9,
          'overdueChecks': 0,
        },
        'domains': [
          {'domain': 'Documents', 'percent': 100},
          {'domain': 'Training', 'percent': 10},
        ],
        'clientFiles': {'residents': 3, 'missingCarePlan': 0, 'missingRoom': 1},
        'medication': {'missed': 0, 'refused': 0, 'late': 0},
        'trend': [
          {'weekStart': '2026-10-26T00:00:00.000Z', 'opened': 0},
        ],
      },
    });

    expect(o.score, 82);
    expect(o.computedAt, isNotNull);
    expect(o.breakdown['expiringCertificates'], 1);
    expect(o.breakdown['incompleteTraining'], 9);
    expect(o.domains.map((d) => d.domain), ['Documents', 'Training']);
    expect(o.domains.last.percent, 10);
    expect(o.clientFiles.residents, 3);
    expect(o.clientFiles.missingRoom, 1);
    expect(o.trend.single.opened, 0);
  });

  test('requirementsFrom maps frequency, priority and archived state', () {
    final list = ComplianceMapper.requirementsFrom({
      'data': [
        {
          'id': 'r1',
          'name': 'Fire safety walk',
          'frequency': 'monthly',
          'priority': 'high',
          'evidenceRequired': true,
          'archivedAt': '2026-10-01T00:00:00.000Z',
          'isActive': false,
        },
        {'id': 'r2', 'name': 'Defaults'},
      ],
    });
    expect(list, hasLength(2));
    expect(list.first.frequency, 'monthly');
    expect(list.first.evidenceRequired, isTrue);
    expect(list.first.isActive, isFalse);
    expect(list.last.frequency, 'quarterly');
    expect(list.last.priority, 'medium');
    expect(list.last.isActive, isTrue);
  });

  test('findingsFrom joins nested residence and client names', () {
    final list = ComplianceMapper.findingsFrom({
      'data': [
        {
          'id': 'f1',
          'title': 'Fire door inspection — not met',
          'severity': 'high',
          'status': 'open',
          'issueOrigin': 'internal_audit',
          'residence': {'id': 'h1', 'name': 'Cozzy Cottege'},
          'client': {'id': 'c1', 'firstName': 'Ada', 'lastName': 'Lovelace'},
          'notes': 'Door 12 does not self-close',
        },
      ],
    });
    final f = list.single;
    expect(f.residenceId, 'h1');
    expect(f.residenceName, 'Cozzy Cottege');
    expect(f.clientName, 'Ada Lovelace');
    expect(f.issueOrigin, 'internal_audit');
    expect(f.notes, 'Door 12 does not self-close');
  });

  test('actionsFrom maps owner and sign-off', () {
    final list = ComplianceMapper.actionsFrom({
      'data': [
        {
          'id': 'a1',
          'incidentId': 'f1',
          'description': 'Replace door closer',
          'status': 'open',
          'owner': {'id': 's1', 'firstName': 'Grace', 'lastName': 'Hopper'},
          'verifiedAt': '2026-11-01T10:00:00.000Z',
        },
      ],
    });
    final a = list.single;
    expect(a.incidentId, 'f1');
    expect(a.ownerName, 'Grace Hopper');
    expect(a.verifiedAt, isNotNull);
  });

  test('auditLogsFrom defaults actor to System', () {
    final list = ComplianceMapper.auditLogsFrom({
      'data': [
        {
          'id': 'l1',
          'action': 'mobile.auth.token.refresh.create',
          'module': 'Mobile',
          'createdAt': '2026-11-02T01:19:00.000Z',
        },
        {
          'id': 'l2',
          'action': 'integrations.quickbooks.connect.create',
          'actorName': 'Adnan Ullah',
        },
      ],
    });
    expect(list.first.actorName, 'System');
    expect(list.first.module, 'Mobile');
    expect(list.last.actorName, 'Adnan Ullah');
  });

  test('label and readinessTone match web wording', () {
    expect(ComplianceMapper.label('internal_audit'), 'Internal Audit');
    expect(ComplianceMapper.label(''), '—');
    expect(ComplianceMapper.readinessTone(95), 'Ready');
    expect(ComplianceMapper.readinessTone(82), 'Watch');
    expect(ComplianceMapper.readinessTone(40), 'At risk');
  });

  test('alertsFrom maps live {type,message,severity,meta} payloads', () {
    final alerts = ComplianceMapper.alertsFrom({
      'data': [
        {
          'type': 'certificate_expired',
          'severity': 'high',
          'message': 'Certificate expired: kkkkkkk (Rifat Islam)',
          'meta': {'staffDocumentId': 'doc-1', 'staffId': 's-1'},
        },
      ],
    });
    expect(alerts, hasLength(1));
    expect(alerts.single.id, 'certificate_expired');
    expect(alerts.single.kind, 'certificate_expired');
    expect(alerts.single.title, contains('Certificate expired'));
    expect(alerts.single.severity, 'high');
  });

  test('exportFrom keeps downloadUrl for Reports & Exports', () {
    final job = ComplianceMapper.exportFrom({
      'data': {
        'id': 'e1',
        'reportKey': 'compliance_findings',
        'status': 'ready',
        'downloadUrl': 'https://example.test/export.csv',
      },
    });
    expect(job?.downloadUrl, 'https://example.test/export.csv');
  });
}
