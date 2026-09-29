import 'package:comprehensive_hr_and_ops/features/staff/incidents/data/mappers/staff_incidents_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detailFrom maps live demo incident fields for web parity', () {
    final detail = StaffIncidentsMapper.detailFrom({
      'id': 'faa63de3-2382-4ba6-991b-9e6428bedac2',
      'title': 'Brief unauthorised absence',
      'status': 'investigating',
      'reportedAt': '2026-08-27T09:33:09.000Z',
      'acknowledgedAt': '2026-09-15T08:52:37.269Z',
      'client': {'name': 'Ayaan Karim'},
      'residence': {'name': 'Elm House'},
      'reporter': {'name': 'Jamal Uddin'},
      'category': {'name': 'Absence from Care'},
      'investigation': {
        'status': 'open',
        'findings': 'Absent',
        'rootCause':
            'Faulty latch, plus no agreed de-escalation plan for screen time.',
        'updatedAt': '2026-09-15T08:52:09.371Z',
        'investigator': {'name': 'Jamal Uddin'},
      },
      'evidence': [
        {
          'fileUrl': '/files/incidents/demo-cctv-still.jpg',
          'fileType': 'image/jpeg',
          'fileName': null,
          'createdAt': '2026-08-27T09:33:09.143Z',
          'uploader': {'name': 'Jamal Uddin'},
        },
      ],
      'payloadJson': {
        'incidentDescription':
            'Absent for 25 minutes. Found at the corner shop and returned willingly.',
        'incidentLocationDescription': 'Rear garden, near the gate.',
        'partiesNotified': {
          'childs_family': {
            'notified': 'yes',
            'contactName': 'Shirin Karim',
            'dateNotified': '2026-08-27',
          },
          'police_rcmp': {'notified': 'no'},
        },
      },
      'templateSnapshotJson': {
        'fields': [
          {
            'key': 'section_1',
            'title': "Section 1: Child or Youth's Information",
            'fields': [
              {'key': 'childLastName', 'label': 'Last Name', 'type': 'text'},
            ],
          },
          {
            'key': 'section_7',
            'title': 'Section 7: Notification',
            'fields': [
              {
                'key': 'partiesNotified',
                'type': 'table',
                'label': 'Parties Notified',
                'rows': [
                  {'key': 'childs_family', 'label': "Child's Family"},
                  {'key': 'police_rcmp', 'label': 'Police / RCMP'},
                ],
              },
            ],
          },
        ],
      },
    });

    expect(detail.title, 'Brief unauthorised absence');
    expect(detail.shortIdLabel, '#faa63de3');
    expect(detail.residentName, 'Ayaan Karim');
    expect(detail.residenceName, 'Elm House');
    expect(detail.reportedByName, 'Jamal Uddin');
    expect(detail.categoryLabel, 'Absence from Care');
    expect(detail.statusLabel, 'Investigating');
    expect(detail.acknowledged, isTrue);
    expect(detail.acknowledgedAtLabel, isNotEmpty);
    // Top description stays empty when only CIR incidentDescription exists.
    expect(detail.description, isEmpty);
    expect(detail.location, 'Rear garden, near the gate.');
    expect(detail.investigationStatus, 'Open');
    expect(detail.investigationFindings, 'Absent');
    expect(
      detail.investigationRootCause,
      'Faulty latch, plus no agreed de-escalation plan for screen time.',
    );
    expect(detail.investigationRecordedBy, 'Jamal Uddin');
    expect(detail.evidence, hasLength(1));
    expect(detail.evidence.first.displayName, 'image/jpeg');
    expect(detail.evidence.first.metaLabel, contains('Jamal Uddin'));
    expect(detail.cirReport, isNotNull);
    expect(detail.cirReport!.formSections, isNotEmpty);

    final familyField = detail.cirReport!.formSections
        .expand((s) => s.fields)
        .firstWhere((f) => f.label.contains("Child's Family"));
    expect(familyField.value.toLowerCase(), contains('yes'));
    expect(familyField.value, contains('Shirin Karim'));
  });

  test('activityFrom humanizes audit actions and marks failures', () {
    final activity = StaffIncidentsMapper.activityFrom({
      'data': [
        {
          'action': 'incidents.acknowledge.create',
          'outcome': 'success',
          'at': '2026-09-15T08:52:53.267Z',
          'actor': {'name': 'Jamal Uddin'},
        },
        {
          'action': 'incidents.update',
          'outcome': 'failure',
          'at': '2026-09-10T11:44:33.275Z',
          'actor': {'name': 'Rafi Ahmed'},
        },
        {
          'action': 'incidents.investigation.update',
          'outcome': 'success',
          'at': '2026-09-10T11:49:29.082Z',
          'actor': {'name': 'Rafi Ahmed'},
        },
      ],
    });

    expect(activity[0].title, 'Acknowledged');
    expect(activity[0].isFailure, isFalse);
    expect(activity[0].meta, contains('Jamal Uddin'));
    expect(activity[1].title, 'Details updated');
    expect(activity[1].isFailure, isTrue);
    expect(activity[2].title, 'Investigation updated');
  });
}
