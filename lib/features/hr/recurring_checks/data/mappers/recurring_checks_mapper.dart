import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/recurring_check.dart';

abstract final class RecurringChecksMapper {
  static List<int> _ints(Map<String, dynamic> json, String key) => [
        for (final v in JsonCodec.listAt(json, key)) ?JsonCodec.integer(v),
      ];

  static String? _clientName(Map<String, dynamic>? client) {
    if (client == null) return null;
    final name = JsonCodec.string(client['name']);
    if (name != null && name.isNotEmpty) return name;
    final joined = [client['firstName'], client['lastName']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    return joined.isEmpty ? null : joined;
  }

  static CheckSchedule? scheduleFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final rules = JsonCodec.mapAt(json, 'alertRules');
    final client = JsonCodec.mapAt(json, 'client');
    return CheckSchedule(
      id: id,
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      name: JsonCodec.string(json['name']),
      checkType: JsonCodec.string(json['checkType']),
      instructions: JsonCodec.string(json['instructions']),
      frequency: JsonCodec.string(json['frequency']),
      intervalMinutes: JsonCodec.integer(json['intervalMinutes']),
      timesOfDay: _ints(json, 'timesOfDay'),
      weekdays: _ints(json, 'weekdays'),
      dayOfMonth: JsonCodec.integer(json['dayOfMonth']),
      assignedRole: JsonCodec.string(json['assignedRole']),
      assignedStaffId: JsonCodec.string(json['assignedStaffId']),
      assignedStaffName: JsonCodec.string(json['assignedStaffName']),
      effectiveFrom: JsonCodec.dateTime(json['effectiveFrom']),
      expiresAt: JsonCodec.dateTime(json['expiresAt']),
      alertEnabled: JsonCodec.boolean(json['alertEnabled']) ?? false,
      alertRules: [
        if (rules != null)
          for (final rule in JsonCodec.listAt(rules, 'rules').whereType<Map>())
            CheckAlertRule(
              field: JsonCodec.stringOr(rule['field'], ''),
              operator: JsonCodec.stringOr(rule['operator'], 'gt'),
              value: rule['value'] ?? '',
              severity: JsonCodec.stringOr(rule['severity'], 'needs_attention'),
              raiseIncident: JsonCodec.boolean(rule['raiseIncident']) ?? false,
            ),
      ],
      notifyRoles: [
        if (rules != null)
          for (final role in JsonCodec.listAt(rules, 'notifyRoles'))
            if (role is String) role,
      ],
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
      activeFromMinute: JsonCodec.integer(json['activeFromMinute']),
      activeToMinute: JsonCodec.integer(json['activeToMinute']),
      clientName: _clientName(client),
      residenceName: JsonCodec.string(JsonCodec.mapAt(json, 'residence')?['name']),
    );
  }

  static List<CheckSchedule> schedulesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?scheduleFrom(JsonCodec.asMap(row)),
      ];

  static CheckSchedulePage schedulePageFrom(
    dynamic body, {
    required int page,
    required int limit,
  }) {
    final items = schedulesFrom(body);
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final total = JsonCodec.integerOr(meta['total'], items.length);
    return CheckSchedulePage(
      items: items,
      page: JsonCodec.integerOr(meta['page'], page),
      limit: JsonCodec.integerOr(meta['limit'], limit),
      total: total,
      totalPages: JsonCodec.integerOr(meta['totalPages'], (total / limit).ceil()),
    );
  }

  static CheckEntry? entryFrom(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final staff = JsonCodec.mapAt(json, 'staff');
    final result = JsonCodec.mapAt(json, 'result');
    return CheckEntry(
      id: id,
      checkName: JsonCodec.string(json['checkName']),
      staffName: _clientName(staff),
      checkedAt: JsonCodec.dateTime(json['checkedAt']),
      note: JsonCodec.stringOr(json['note'], ''),
      recordedOnDuty: JsonCodec.boolean(json['recordedOnDuty']),
      coveredForName: JsonCodec.string(JsonCodec.mapAt(json, 'coveredFor')?['name']),
      takeoverReason: JsonCodec.string(json['takeoverReason']),
      result: result == null ? const {} : Map<String, Object?>.from(result),
      outcome: JsonCodec.string(json['outcome']),
    );
  }

  static List<CheckEntry> entriesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?entryFrom(JsonCodec.asMap(row)),
      ];

  static List<CheckInstance> instancesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?_instance(JsonCodec.asMap(row)),
      ];

  static CheckInstance? _instance(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final dueAt = JsonCodec.dateTime(json['dueAt']);
    if (id == null || dueAt == null) return null;
    final client = JsonCodec.mapAt(json, 'client');
    return CheckInstance(
      id: id,
      scheduleId: JsonCodec.stringOr(json['scheduleId'], ''),
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      dueAt: dueAt,
      status: JsonCodec.stringOr(json['status'], 'pending'),
      statusNote: JsonCodec.string(json['statusNote']),
      statusOnDuty: JsonCodec.boolean(json['statusOnDuty']),
      assignedRole: JsonCodec.string(json['assignedRole']),
      assignedStaffId: JsonCodec.string(json['assignedStaffId']),
      assignedStaffName: JsonCodec.string(json['assignedStaffName']),
      checkName: JsonCodec.string(json['checkName']),
      checkType: JsonCodec.string(json['checkType']),
      instructions: JsonCodec.string(json['instructions']),
      clientName: _clientName(client),
      roomNumber: JsonCodec.string(client?['roomNumber']),
      entry: entryFrom(JsonCodec.mapAt(json, 'entry')),
    );
  }

  static List<CheckAvailableStaff> availableStaffFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['staffId']) case final staffId?)
            CheckAvailableStaff(
              staffId: staffId,
              name: JsonCodec.stringOr(row['name'], 'Staff'),
              shiftTitle: JsonCodec.string(row['shiftTitle']),
              shiftStartsAt: JsonCodec.dateTime(row['shiftStartsAt']),
              shiftEndsAt: JsonCodec.dateTime(row['shiftEndsAt']),
            ),
      ];

  static String _personName(Map row, {String empty = ''}) {
    final name = [row['firstName'], row['lastName']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    return name.isEmpty ? empty : name;
  }

  static List<CheckOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            CheckOption(id: id, label: JsonCodec.stringOr(row['name'], 'Residence')),
      ];

  static List<CheckOption> peopleFrom(dynamic body, {String empty = ''}) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            CheckOption(id: id, label: _personName(row, empty: empty)),
      ];

  static String? openAttendanceResidence(dynamic body) {
    for (final row in JsonCodec.unwrapList(body).whereType<Map>()) {
      if (row['checkInAt'] != null && row['checkOutAt'] == null) {
        return JsonCodec.string(row['residenceId']) ?? '';
      }
    }
    return null;
  }
}
