import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/handover_options.dart';
import '../../domain/entities/shift_handover.dart';

abstract final class HandoversMapper {
  static List<ShiftHandover> listFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          ?handoverFrom(JsonCodec.asMap(row)),
      ];

  static ShiftHandover? handoverFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final flag = JsonCodec.mapAt(json, 'flagForAttention');
    return ShiftHandover(
      id: id,
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      residenceName: JsonCodec.string(JsonCodec.mapAt(json, 'residence')?['name']),
      fromShiftId: JsonCodec.string(json['fromShiftId']),
      fromShiftStartsAt:
          JsonCodec.dateTime(JsonCodec.mapAt(json, 'fromShift')?['startsAt']),
      toShiftStartsAt:
          JsonCodec.dateTime(JsonCodec.mapAt(json, 'toShift')?['startsAt']),
      summary: JsonCodec.stringOr(json['summary'], ''),
      status: JsonCodec.stringOr(json['status'], 'submitted'),
      pendingActions: [
        for (final action in JsonCodec.listAt(json, 'pendingActions'))
          if (action is String)
            action
          else if (action is Map)
            ?JsonCodec.string(action['title']),
      ],
      clientUpdates: [
        for (final row in JsonCodec.listAt(json, 'clientUpdates').whereType<Map>())
          _clientUpdate(JsonCodec.asMap(row)),
      ],
      alertingCount: JsonCodec.integerOr(json['alertingCount'], 0),
      needsAcknowledgement: JsonCodec.boolean(json['needsAcknowledgement']) ?? false,
      incidents: [
        for (final row in JsonCodec.listAt(json, 'incidents').whereType<Map>())
          _incident(JsonCodec.asMap(row)),
      ],
      comments: [
        for (final row in JsonCodec.listAt(json, 'comments').whereType<Map>())
          _comment(JsonCodec.asMap(row)),
      ],
      tasks: [
        for (final row in JsonCodec.listAt(json, 'tasks').whereType<Map>())
          _task(JsonCodec.asMap(row)),
      ],
      acknowledgements: [
        for (final row in JsonCodec.listAt(json, 'acknowledgements').whereType<Map>())
          _acknowledgement(JsonCodec.asMap(row)),
      ],
      flagCategory: flag?['category'] is String ? flag!['category'] as String : null,
      createdBy: JsonCodec.string(json['createdBy']),
      authorName: JsonCodec.string(JsonCodec.mapAt(json, 'author')?['name']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static HandoverAnnouncement? announcementFrom(dynamic body) {
    final announced = JsonCodec.mapAt(JsonCodec.unwrapMap(body), 'announcedTo');
    final mode = JsonCodec.string(announced?['mode']);
    if (announced == null || mode == null) return null;
    return HandoverAnnouncement(
      mode: mode,
      recipients: JsonCodec.integerOr(announced['recipients'], 0),
    );
  }

  /// Only non-blank string entries, as the web detail lists them.
  static Map<String, String> _textEntries(Map<String, dynamic>? values) => {
        for (final entry in (values ?? const <String, dynamic>{}).entries)
          if (entry.value is String && (entry.value as String).trim().isNotEmpty)
            entry.key: entry.value as String,
      };

  static HandoverClientUpdate _clientUpdate(Map<String, dynamic> json) {
    final care = JsonCodec.mapAt(json, 'care');
    return HandoverClientUpdate(
      id: JsonCodec.stringOr(json['id'], JsonCodec.stringOr(json['clientId'], '')),
      clientName: JsonCodec.string(json['clientName']),
      status: JsonCodec.stringOr(json['status'], 'stable'),
      health: _textEntries(JsonCodec.mapAt(json, 'health')),
      medication: _textEntries(JsonCodec.mapAt(json, 'medication')),
      care: care == null
          ? null
          : HandoverCare(
              completed: [
                for (final item in JsonCodec.listAt(care, 'completed'))
                  if (item is String) item,
              ],
              otherCompleted: _nonBlank(care['otherCompleted']),
              pending: _nonBlank(care['pending']),
              followUpRequired: _nonBlank(care['followUpRequired']),
            ),
    );
  }

  static String? _nonBlank(dynamic value) {
    final text = JsonCodec.string(value);
    return text == null || text.trim().isEmpty ? null : text;
  }

  static HandoverIncident _incident(Map<String, dynamic> json) => HandoverIncident(
        id: JsonCodec.stringOr(json['id'], ''),
        reference: JsonCodec.string(json['reference']),
        title: JsonCodec.string(json['title']),
        severity: JsonCodec.string(json['severity']),
        categoryName: JsonCodec.string(JsonCodec.mapAt(json, 'category')?['name']),
      );

  static HandoverComment _comment(Map<String, dynamic> json) => HandoverComment(
        id: JsonCodec.stringOr(json['id'], ''),
        body: JsonCodec.stringOr(json['body'], ''),
        authorName: JsonCodec.string(JsonCodec.mapAt(json, 'author')?['name']),
        createdAt: JsonCodec.dateTime(json['createdAt']),
      );

  static HandoverTask _task(Map<String, dynamic> json) => HandoverTask(
        id: JsonCodec.stringOr(json['id'], ''),
        title: JsonCodec.stringOr(json['title'], ''),
        status: JsonCodec.stringOr(json['status'], 'open'),
        priority: JsonCodec.string(json['priority']),
        assigneeFirstNames: [
          for (final a in JsonCodec.listAt(json, 'assignees').whereType<Map>())
            ?JsonCodec.string(
              JsonCodec.mapAt(JsonCodec.asMap(a), 'staff')?['firstName'],
            ),
        ],
      );

  static HandoverAcknowledgement _acknowledgement(Map<String, dynamic> json) =>
      HandoverAcknowledgement(
        userId: JsonCodec.stringOr(json['userId'], ''),
        staffFirstName:
            JsonCodec.string(JsonCodec.mapAt(json, 'staff')?['firstName']),
        userName: JsonCodec.string(JsonCodec.mapAt(json, 'user')?['name']),
        createdAt: JsonCodec.dateTime(json['createdAt']),
      );

  static List<HandoverOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HandoverOption(id: id, label: JsonCodec.stringOr(row['name'], 'Residence')),
      ];

  static List<HandoverOption> staffFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HandoverOption(
              id: id,
              label: [row['firstName'], row['lastName']]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' ')
                  .trim(),
            ),
      ];

  static List<HandoverOption> clientsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HandoverOption(
              id: id,
              label: () {
                final name = [row['firstName'], row['lastName']]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join(' ');
                return name.isEmpty ? 'Unnamed' : name;
              }(),
            ),
      ];

  /// Non-cancelled `/shifts` rows.
  static List<HandoverShift> shiftsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            if (JsonCodec.string(row['status']) != 'cancelled')
              HandoverShift(
                id: id,
                residenceId: JsonCodec.string(row['residenceId']),
                residenceName: JsonCodec.string(row['residenceName']),
                title: JsonCodec.string(row['title']),
                shiftType: JsonCodec.string(row['shiftType']),
                startsAt: JsonCodec.dateTime(row['startsAt']),
                endsAt: JsonCodec.dateTime(row['endsAt']),
                staff: [
                  for (final person
                      in JsonCodec.listAt(JsonCodec.asMap(row), 'staff').whereType<Map>())
                    if (JsonCodec.string(person['id']) case final staffId?)
                      HandoverShiftStaff(
                        id: staffId,
                        name: JsonCodec.string(person['name']),
                        status: JsonCodec.string(person['status']),
                      ),
                ],
              ),
      ];

  /// Shift ids from `/attendance?mine=true` rows that were clocked in to.
  static Set<String> clockedInShiftIds(dynamic body) => {
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (row['checkInAt'] != null)
            ?JsonCodec.string(row['shiftId']),
      };
}
