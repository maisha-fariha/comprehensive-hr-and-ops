import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/emergency_alert.dart';

class EmergencyMapper {
  const EmergencyMapper._();

  static EmergencyPerson? _person(dynamic raw) {
    if (raw is! Map) return null;
    final json = JsonCodec.asMap(raw);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final name = JsonCodec.string(json['name']) ??
        [json['firstName'], json['lastName']]
            .map((p) => JsonCodec.string(p) ?? '')
            .where((p) => p.isNotEmpty)
            .join(' ');
    return EmergencyPerson(
      id: id,
      name: name.isEmpty ? null : name,
      phone: JsonCodec.string(json['phone']),
    );
  }

  static EmergencyAction? _action(dynamic raw) {
    if (raw is! Map) return null;
    final json = JsonCodec.asMap(raw);
    final id = JsonCodec.string(json['id']);
    final action = JsonCodec.string(json['action']);
    if (id == null || action == null) return null;
    return EmergencyAction(
      id: id,
      action: action,
      actorName: _person(json['actor'])?.name,
      targetName: _person(json['targetUser'])?.name,
      note: JsonCodec.string(json['note']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static EmergencyAlert? alertFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence') ?? const {};
    final client = _person(json['client']);
    return EmergencyAlert(
      id: id,
      type: JsonCodec.stringOr(json['type'], 'other'),
      status: JsonCodec.stringOr(json['status'], 'active'),
      priority: JsonCodec.string(json['priority']),
      note: JsonCodec.string(json['note']),
      locationNote: JsonCodec.string(json['locationNote']),
      residenceName: JsonCodec.string(residence['name']),
      residencePhone: JsonCodec.string(residence['phone']),
      residenceEmergencyPhone: JsonCodec.string(residence['emergencyPhone']),
      clientName: client?.name,
      raiser: _person(json['raiser']),
      acknowledger: _person(json['acknowledger']),
      assignee: _person(json['assignee']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      acknowledgedAt: JsonCodec.dateTime(json['acknowledgedAt']),
      resolvedAt: JsonCodec.dateTime(json['resolvedAt']),
      resolutionNote: JsonCodec.string(json['resolutionNote']),
      actions: [
        for (final raw in JsonCodec.listAt(json, 'actions'))
          ?_action(raw),
      ],
      attachments: [
        for (final raw in JsonCodec.listAt(json, 'attachments').whereType<Map>())
          if (JsonCodec.string(raw['fileUrl']) case final url?)
            EmergencyAttachment(
              id: JsonCodec.stringOr(raw['id'], url),
              fileUrl: url,
            ),
      ],
    );
  }

  static EmergencyAlertPage pageFrom(dynamic body) {
    final items = [
      for (final row in JsonCodec.unwrapList(body).whereType<Map>())
        ?alertFrom(JsonCodec.asMap(row)),
    ];
    final meta = JsonCodec.metaOf(body);
    return EmergencyAlertPage(
      items: items,
      total: JsonCodec.integer(meta?['total']) ?? items.length,
    );
  }

  static List<EmergencyOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            EmergencyOption(
              id: id,
              label: JsonCodec.stringOr(row['name'], 'Residence'),
            ),
      ];
}
