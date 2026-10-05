import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/referral.dart';

class AdmissionsMapper {
  const AdmissionsMapper._();

  static ReferralBoard boardFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return ReferralBoard(
      pending: JsonCodec.integerOr(json['pending'], 0),
      awaitingDocuments: JsonCodec.integerOr(json['awaitingDocuments'], 0),
      assessmentPending: JsonCodec.integerOr(json['assessmentPending'], 0),
      admittedLast30Days: JsonCodec.integerOr(json['admittedLast30Days'], 0),
    );
  }

  static List<IntakeField> _fields(dynamic raw) => [
        if (raw is List)
          for (final row in raw.whereType<Map>())
            if (JsonCodec.string(row['key']) case final key?)
              IntakeField(
                key: key,
                label: JsonCodec.stringOr(row['label'], key),
                type: JsonCodec.stringOr(row['type'], 'text'),
                required: JsonCodec.boolean(row['required']) ?? false,
                options: [
                  if (row['options'] is List)
                    for (final o in row['options'] as List)
                      ?JsonCodec.string(o),
                ],
                target: JsonCodec.string(row['target']),
              ),
      ];

  static List<IntakeChecklistItem> _checklist(dynamic raw) => [
        if (raw is List)
          for (final row in raw.whereType<Map>())
            if (JsonCodec.string(row['key']) case final key?)
              IntakeChecklistItem(
                key: key,
                label: JsonCodec.stringOr(row['label'], key),
                required: JsonCodec.boolean(row['required']) ?? false,
                requiresDocument:
                    JsonCodec.boolean(row['requiresDocument']) ?? false,
              ),
      ];

  static IntakeTemplate? templateFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return IntakeTemplate(
      id: id,
      name: JsonCodec.stringOr(json['name'], 'Intake form'),
      provinceOrState: JsonCodec.string(json['provinceOrState']),
      version: JsonCodec.integer(json['version']),
      isActive: JsonCodec.boolean(json['isActive']),
      fields: _fields(json['fieldsJson']),
      checklist: _checklist(json['checklistJson']),
    );
  }

  static List<IntakeTemplate> templatesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?templateFrom(JsonCodec.asMap(row)),
      ];

  static TemplateSnapshot? _snapshot(dynamic raw) {
    if (raw is! Map) return null;
    final json = JsonCodec.asMap(raw);
    return TemplateSnapshot(
      name: JsonCodec.string(json['name']),
      version: JsonCodec.integer(json['version']),
      fields: _fields(json['fields']),
      checklist: _checklist(json['checklist']),
    );
  }

  static Referral? referralFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final checklist = JsonCodec.mapAt(json, 'checklistJson') ?? const {};
    final completed = checklist['completed'];
    return Referral(
      id: id,
      firstName: JsonCodec.stringOr(json['firstName'], ''),
      lastName: JsonCodec.stringOr(json['lastName'], ''),
      status: JsonCodec.stringOr(json['status'], 'new'),
      dateOfBirth: JsonCodec.dateTime(json['dateOfBirth']),
      source: JsonCodec.string(json['source']),
      admissionType: JsonCodec.string(json['admissionType']),
      expectedAdmissionDate: JsonCodec.dateTime(json['expectedAdmissionDate']),
      reasonForAdmission: JsonCodec.string(json['reasonForAdmission']),
      contactName: JsonCodec.string(json['contactName']),
      contactPhone: JsonCodec.string(json['contactPhone']),
      contactEmail: JsonCodec.string(json['contactEmail']),
      notes: JsonCodec.string(json['notes']),
      priority: JsonCodec.integer(json['priority']),
      preferredResidenceId: JsonCodec.string(json['preferredResidenceId']),
      snapshot: _snapshot(json['templateSnapshotJson']),
      payload: JsonCodec.mapAt(json, 'payloadJson') ?? const {},
      completedChecklist: [
        if (completed is List)
          for (final key in completed) ?JsonCodec.string(key),
      ],
      waitlistedAt: JsonCodec.dateTime(json['waitlistedAt']),
      closedReason: JsonCodec.string(json['closedReason']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      assessments: [
        for (final row in JsonCodec.listAt(json, 'assessments').whereType<Map>())
          if (JsonCodec.string(row['id']) case final aid?)
            ReferralAssessment(
              id: aid,
              summary: JsonCodec.stringOr(row['summary'], ''),
              outcome: JsonCodec.string(row['outcome']),
              assessedAt: JsonCodec.dateTime(row['assessedAt']),
            ),
      ],
      contacts: [
        for (final row in JsonCodec.listAt(json, 'contacts').whereType<Map>())
          if (JsonCodec.string(row['name']) case final name?)
            ReferralContact(
              id: JsonCodec.string(row['id']),
              name: name,
              relationship: JsonCodec.string(row['relationship']),
              phone: JsonCodec.string(row['phone']),
              email: JsonCodec.string(row['email']),
              address: JsonCodec.string(row['address']),
              isPrimaryGuardian:
                  JsonCodec.boolean(row['isPrimaryGuardian']) ?? false,
              isEmergencyContact:
                  JsonCodec.boolean(row['isEmergencyContact']) ?? false,
            ),
      ],
      events: [
        for (final row in JsonCodec.listAt(json, 'events').whereType<Map>())
          if ((JsonCodec.string(row['id']), JsonCodec.string(row['event']))
              case (final eid?, final event?))
            ReferralEvent(
              id: eid,
              event: event,
              fromStatus: JsonCodec.string(row['fromStatus']),
              toStatus: JsonCodec.string(row['toStatus']),
              note: JsonCodec.string(row['note']),
              createdAt: JsonCodec.dateTime(row['createdAt']),
              actorName: row['actor'] is Map
                  ? JsonCodec.string((row['actor'] as Map)['name'])
                  : null,
            ),
      ],
      documents: [
        for (final row in JsonCodec.listAt(json, 'documents').whereType<Map>())
          if ((JsonCodec.string(row['id']), JsonCodec.string(row['fileUrl']))
              case (final did?, final url?))
            ReferralDocument(
              id: did,
              name: JsonCodec.stringOr(row['name'], url.split('/').last),
              fileUrl: url,
              checklistKey: JsonCodec.string(row['checklistKey']),
            ),
      ],
    );
  }

  static ReferralPage pageFrom(dynamic body) {
    final items = [
      for (final row in JsonCodec.unwrapList(body).whereType<Map>())
        ?referralFrom(JsonCodec.asMap(row)),
    ];
    final meta = JsonCodec.metaOf(body);
    return ReferralPage(
      items: items,
      total: JsonCodec.integer(meta?['total']) ?? items.length,
      totalPages: JsonCodec.integer(meta?['totalPages']) ?? 1,
    );
  }

  static List<AdmissionOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            AdmissionOption(
              id: id,
              label: JsonCodec.stringOr(row['name'], 'Residence'),
            ),
      ];

  static List<AdmissionRoom> roomsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            AdmissionRoom(
              id: id,
              name: JsonCodec.stringOr(row['name'], 'Room'),
              roomType: JsonCodec.string(row['roomType']),
              isActive: JsonCodec.boolean(row['isActive']) ?? false,
              available: JsonCodec.integerOr(row['available'], 0),
            ),
      ];
}
