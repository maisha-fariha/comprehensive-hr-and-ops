import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/mar_administration.dart';
import '../../domain/entities/mar_medication.dart';
import '../../domain/entities/mar_options.dart';
import '../../domain/entities/mar_round.dart';

abstract final class MedicationMapper {
  static List<Map<String, dynamic>> _rows(dynamic body) =>
      JsonCodec.unwrapList(body).whereType<Map>().map(JsonCodec.asMap).toList();

  static List<String> _strings(dynamic value) => value is List
      ? value.map(JsonCodec.string).whereType<String>().toList()
      : const [];

  static List<int> _ints(dynamic value) => value is List
      ? value.map(JsonCodec.integer).whereType<int>().toList()
      : const [];

  /// The web's `toISOString().slice(0, 10)`.
  static String _isoDay(dynamic value) {
    final parsed = JsonCodec.dateTime(value)?.toUtc();
    if (parsed == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
  }

  static String? _nameOf(Map<String, dynamic>? json) => json == null
      ? null
      : JsonCodec.string(json['name']) ??
          JsonCodec.string(
            [json['firstName'], json['lastName']]
                .map(JsonCodec.string)
                .whereType<String>()
                .join(' ')
                .trim(),
          );

  static MarOccurrence occurrenceFrom(Map<String, dynamic> json) => MarOccurrence(
        id: JsonCodec.stringOr(json['id'], ''),
        medicationId: JsonCodec.stringOr(json['medicationId'], ''),
        clientId: JsonCodec.stringOr(json['clientId'], ''),
        clientName: JsonCodec.string(json['clientName']),
        allergies: _strings(json['clientAllergies']),
        residenceId: JsonCodec.stringOr(json['residenceId'], ''),
        residenceName: JsonCodec.string(json['residenceName']),
        name: JsonCodec.stringOr(json['name'], ''),
        dose: JsonCodec.string(json['dose']),
        isControlled: JsonCodec.boolean(json['isControlled']) ?? false,
        scheduledTime: JsonCodec.stringOr(json['scheduledTime'], ''),
        dueAt: JsonCodec.dateTime(json['dueAt']),
        state: JsonCodec.stringOr(json['state'], 'upcoming'),
        scheduled: JsonCodec.boolean(json['scheduled']) ?? true,
        administrationId: JsonCodec.string(json['administrationId']),
        administeredAt: JsonCodec.dateTime(json['administeredAt']),
        administeredBy: JsonCodec.string(json['administeredBy']),
      );

  static MarRound roundFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final summary = JsonCodec.mapAt(json, 'summary') ?? const {};
    return MarRound(
      occurrences: JsonCodec.listAt(json, 'occurrences')
          .whereType<Map>()
          .map((o) => occurrenceFrom(JsonCodec.asMap(o)))
          .toList(),
      summary: MarSummary(
        scheduled: JsonCodec.integerOr(summary['scheduled'], 0),
        administered: JsonCodec.integerOr(summary['administered'], 0),
        unscheduled: JsonCodec.integerOr(summary['unscheduled'], 0),
        missed: JsonCodec.integerOr(summary['missed'], 0),
        complianceRate: JsonCodec.number(summary['complianceRate'])?.round(),
      ),
    );
  }

  static MarMedication medicationFrom(Map<String, dynamic> json) {
    final schedule = JsonCodec.mapAt(json, 'schedule');
    return MarMedication(
      id: JsonCodec.stringOr(json['id'], ''),
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      name: JsonCodec.stringOr(json['name'], ''),
      dose: JsonCodec.string(json['dose']),
      frequency: JsonCodec.string(schedule?['frequency']) ??
          JsonCodec.stringOr(json['scheduleFrequency'], ''),
      times: _strings(schedule?['times'] ?? json['scheduleTimes']),
      weekdays: _ints(schedule?['weekdays'] ?? json['scheduleWeekdays']),
      route: JsonCodec.stringOr(json['route'], ''),
      startsAt: _isoDay(json['startsAt']),
      endsAt: _isoDay(json['endsAt']),
      stockUnitsPerDose: JsonCodec.integer(json['stockUnitsPerDose']),
      isControlled: JsonCodec.boolean(json['isControlled']) ?? false,
      requiresCheckScheduleId: JsonCodec.string(json['requiresCheckScheduleId']),
      requiresCheckWithinMinutes: JsonCodec.integer(json['requiresCheckWithinMinutes']),
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
    );
  }

  static MarMedication prnFrom(Map<String, dynamic> json) => MarMedication(
        id: JsonCodec.stringOr(json['id'], ''),
        isPrn: true,
        clientId: JsonCodec.stringOr(json['clientId'], ''),
        residenceId: JsonCodec.stringOr(json['residenceId'], ''),
        name: JsonCodec.stringOr(json['name'], ''),
        dose: JsonCodec.string(json['dose']),
        instructions: JsonCodec.stringOr(json['instructions'], ''),
        stockUnitsPerDose: JsonCodec.integer(json['stockUnitsPerDose']),
        minIntervalMinutes: JsonCodec.integer(json['minIntervalMinutes']),
        isControlled: JsonCodec.boolean(json['isControlled']) ?? false,
        isActive: JsonCodec.boolean(json['isActive']) ?? true,
        lastAdministeredAt: JsonCodec.dateTime(json['lastAdministeredAt']),
      );

  static List<MarMedication> medicationsFrom(dynamic body) =>
      _rows(body).map(medicationFrom).toList();

  static List<MarMedication> prnsFrom(dynamic body) => _rows(body).map(prnFrom).toList();

  static MarAdministration administrationFrom(Map<String, dynamic> json) {
    final medication = JsonCodec.mapAt(json, 'medication');
    return MarAdministration(
      id: JsonCodec.stringOr(json['id'], ''),
      medicationName: JsonCodec.stringOr(medication?['name'], '—'),
      dose: JsonCodec.string(medication?['dose']),
      isControlled: JsonCodec.boolean(medication?['isControlled']) ?? false,
      clientName: _nameOf(JsonCodec.mapAt(json, 'client')) ?? '—',
      status: JsonCodec.stringOr(json['status'], ''),
      administeredAt: JsonCodec.dateTime(json['administeredAt']),
      administeredBy: JsonCodec.string(json['administeredBy']),
      administeredByName: _nameOf(JsonCodec.mapAt(json, 'administeredByStaff')),
      witnessName: _nameOf(
        JsonCodec.mapAt(json, 'witnessStaff') ?? JsonCodec.mapAt(json, 'witness'),
      ),
      wasLate: JsonCodec.boolean(json['wasLate']) ?? false,
      administeredOnDuty: JsonCodec.boolean(json['administeredOnDuty']),
      witnessOnDuty: JsonCodec.boolean(json['witnessOnDuty']),
      amendsAdministrationId: JsonCodec.string(json['amendsAdministrationId']),
      amendmentReason: JsonCodec.string(json['amendmentReason']),
      supersededById: JsonCodec.string(json['supersededById']),
    );
  }

  static List<MarAdministration> administrationsFrom(dynamic body) =>
      _rows(body).map(administrationFrom).toList();

  static MarResidentChart chartFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final client = JsonCodec.mapAt(json, 'client') ?? const {};
    final buckets = JsonCodec.mapAt(json, 'buckets') ?? const {};
    List<MarOccurrence> doses(dynamic list) => list is List
        ? list.whereType<Map>().map((o) => occurrenceFrom(JsonCodec.asMap(o))).toList()
        : const [];
    return MarResidentChart(
      allergies: _strings(client['allergies']),
      buckets: {
        for (final key in const ['morning', 'afternoon', 'evening', 'night'])
          key: doses(buckets[key]),
      },
      unscheduled: doses(json['unscheduled']),
      prn: JsonCodec.listAt(json, 'prn').whereType<Map>().map((raw) {
        final p = JsonCodec.asMap(raw);
        return MarChartPrn(
          id: JsonCodec.stringOr(p['id'], ''),
          name: JsonCodec.stringOr(p['name'], ''),
          lastAdministeredAt: JsonCodec.dateTime(p['lastAdministeredAt']),
          minIntervalMinutes: JsonCodec.integer(p['minIntervalMinutes']),
          availableInMinutes: JsonCodec.integer(p['availableInMinutes']),
        );
      }).toList(),
    );
  }

  static List<MarOption> residencesFrom(dynamic body) => [
        for (final r in _rows(body))
          if (JsonCodec.string(r['id']) case final id?)
            MarOption(id: id, label: JsonCodec.stringOr(r['name'], '—')),
      ];

  static List<MarClientOption> clientsFrom(dynamic body) => [
        for (final c in _rows(body))
          if (JsonCodec.string(c['id']) case final id?)
            MarClientOption(
              id: id,
              name: _nameOf({'firstName': c['firstName'], 'lastName': c['lastName']}) ??
                  'Unnamed',
              residenceId: JsonCodec.stringOr(c['residenceId'], ''),
            ),
      ];

  static List<MarOption> approvedStaffFrom(dynamic body) => [
        for (final s in _rows(body))
          if (JsonCodec.boolean(s['medAdminApproved']) == true)
            if (JsonCodec.string(s['id']) case final id?)
              MarOption(id: id, label: _nameOf(s) ?? '—'),
      ];

  static List<MarOption> witnessesFrom(dynamic body) => [
        for (final w in _rows(body))
          if (JsonCodec.string(w['id']) case final id?)
            MarOption(id: id, label: _nameOf(w) ?? '—'),
      ];

  static List<MarOption> checkSchedulesFrom(dynamic body) => [
        for (final c in _rows(body))
          if (JsonCodec.boolean(c['isActive']) != false)
            if (JsonCodec.string(c['id']) case final id?)
              MarOption(id: id, label: JsonCodec.stringOr(c['name'], 'Recurring check')),
      ];

  static String? _isoMidnight(String day) {
    final parsed = DateTime.tryParse(day.trim());
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day).toIso8601String();
  }

  static num? _number(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? double.tryParse(t);
  }

  static String? _blank(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  /// The API rejects `route: null`: a blank route is left out of a create
  /// and sent as `''` on an update so a cleared route is saved.
  static String? _route(String text, bool update) => update ? text.trim() : _blank(text);

  /// The web `tS` schedule item (also the batch item).
  static Map<String, dynamic> prescriptionItem(MarMedicineDraft d, {bool update = false}) {
    final checkId = _blank(d.requiresCheckScheduleId);
    final within = _number(d.requiresCheckWithinMinutes);
    return {
      'name': d.name.trim(),
      'dose': ?_blank(d.dose),
      'schedule': {
        'frequency': d.frequency,
        if (d.times.isNotEmpty) 'times': d.times,
        if (d.frequency == 'weekly') 'weekdays': d.weekdays,
      },
      'isControlled': d.isControlled,
      'route': ?_route(d.route, update),
      'startsAt': _isoMidnight(d.startsAt),
      'endsAt': _isoMidnight(d.endsAt),
      'stockUnitsPerDose': _number(d.stockUnitsPerDose),
      'requiresCheckScheduleId': checkId,
      'requiresCheckWithinMinutes':
          checkId == null ? null : (within == null || within == 0 ? 60 : within),
    };
  }

  /// `POST /medications` and `PATCH /medications/:id`.
  static Map<String, dynamic> prescriptionBody(MarMedicineDraft d, {bool update = false}) => {
        'clientId': d.clientId,
        'residenceId': d.residenceId,
        ...prescriptionItem(d, update: update),
      };

  /// `POST /medications/batch` — written together, or none is.
  static Map<String, dynamic> prescriptionBatchBody(List<MarMedicineDraft> drafts) => {
        'clientId': drafts.first.clientId,
        'residenceId': drafts.first.residenceId,
        'items': [for (final d in drafts) prescriptionItem(d)],
      };

  /// The web `tA` body: `POST /prn-medications` and `PATCH /prn-medications/:id`.
  static Map<String, dynamic> prnBody(MarMedicineDraft d, {bool update = false}) => {
        'residenceId': d.residenceId,
        'name': d.name.trim(),
        'clientId': ?_blank(d.clientId),
        'dose': ?_blank(d.dose),
        'instructions': ?_blank(d.instructions),
        'isControlled': d.isControlled,
        'minIntervalMinutes': _number(d.minIntervalMinutes),
        'stockUnitsPerDose': _number(d.stockUnitsPerDose),
        'route': ?_route(d.route, update),
        'startsAt': _isoMidnight(d.startsAt),
        'endsAt': _isoMidnight(d.endsAt),
        'requiresCheckScheduleId': _blank(d.requiresCheckScheduleId),
        'requiresCheckWithinMinutes': _number(d.requiresCheckWithinMinutes),
      };

  /// `POST /prn-medications/batch` — each added on its own.
  static Map<String, dynamic> prnBatchBody(List<MarMedicineDraft> drafts) => {
        'residenceId': drafts.first.residenceId,
        'clientId': ?_blank(drafts.first.clientId),
        'items': [
          for (final d in drafts)
            Map.of(prnBody(d))
              ..remove('residenceId')
              ..remove('clientId'),
        ],
      };

  /// `POST /mar/administrations/round`.
  static Map<String, dynamic> roundBody(MarRoundDraft d) {
    final anyCheck = d.safetyChecks.values.any((v) => v);
    final vitals = <String, String>{
      for (final e in d.vitals.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value,
    };
    return {
      'clientId': d.clientId,
      'residenceId': d.residenceId,
      'staffId': d.staffId,
      'administeredAt': ?d.administeredAt?.toUtc().toIso8601String(),
      'items': [
        for (final item in d.items)
          {
            'source': item.isPrn ? 'prn' : 'prescribed',
            if (item.isPrn)
              'prnMedicationId': item.medicationId
            else
              'medicationId': item.medicationId,
            'status': item.status,
            if (item.status != 'administered' && item.doseReason.isNotEmpty)
              'reason': item.doseReason,
            'witnessStaffId': ?_blank(item.witnessStaffId),
            'notes': ?_blank(item.notes),
            'clinicalNotes': ?_blank(item.clinicalNotes),
            if (item.status == 'administered' && anyCheck) 'safetyChecks': d.safetyChecks,
            if (item.status == 'administered' && vitals.isNotEmpty) 'vitals': vitals,
          },
      ],
    };
  }

  static String _cell(String value) {
    final text = value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    return text.contains(RegExp('[,"]')) ? '"${text.replaceAll('"', '""')}"' : text;
  }

  /// CSV of `GET /mar/administrations` rows for roles that cannot poll the
  /// report export.
  static String csvFrom(List<Map<String, dynamic>> rows) {
    final buffer = StringBuffer()
      ..writeln('Given,Resident,Medicine,Dose,Outcome,Signed,Witness,Correction');
    for (final json in rows) {
      final a = administrationFrom(json);
      buffer.writeln(
        [
          a.administeredAt?.toUtc().toIso8601String() ?? '',
          a.clientName,
          a.medicationName,
          a.dose ?? '',
          a.status,
          a.administeredByName ?? '',
          a.witnessName ?? '',
          a.amendmentReason ?? '',
        ].map(_cell).join(','),
      );
    }
    return buffer.toString();
  }
}
