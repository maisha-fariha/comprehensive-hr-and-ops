import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/hr_appointment.dart';

abstract final class HrAppointmentsMapper {
  static String? _name(Map<String, dynamic> json, String key) =>
      JsonCodec.string(JsonCodec.mapAt(json, key)?['name']);

  static HrAppointment? appointmentFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final requester = JsonCodec.mapAt(json, 'requester');
    return HrAppointment(
      id: id,
      type: JsonCodec.stringOr(json['type'], 'external'),
      status: JsonCodec.stringOr(json['status'], 'pending'),
      clientId: JsonCodec.stringOr(json['clientId'], ''),
      clientName: _name(json, 'client'),
      residenceId: JsonCodec.string(json['residenceId']),
      residenceName: _name(json, 'residence'),
      requesterName: JsonCodec.string(requester?['name']),
      requesterEmail: JsonCodec.string(requester?['email']),
      relationship: JsonCodec.string(json['requesterRelationship']),
      scheduledAt: JsonCodec.dateTime(json['scheduledAt']),
      location: JsonCodec.string(json['location']),
      purpose: JsonCodec.string(json['purpose']),
      notes: JsonCodec.string(json['notes']),
      deciderName: _name(json, 'decider'),
      decidedAt: JsonCodec.dateTime(json['decidedAt']),
      decisionReason: JsonCodec.string(json['decisionReason']),
    );
  }

  static HrAppointmentPage pageFrom(dynamic body) {
    final items = [
      for (final row in JsonCodec.unwrapList(body).whereType<Map>())
        ?appointmentFrom(JsonCodec.asMap(row)),
    ];
    final meta = JsonCodec.metaOf(body);
    return HrAppointmentPage(
      items: items,
      total: JsonCodec.integer(meta?['total']) ?? items.length,
      totalPages: JsonCodec.integer(meta?['totalPages']) ?? (items.isEmpty ? 0 : 1),
    );
  }

  static HrAppointmentSummary summaryFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    int n(String key) => JsonCodec.integerOr(json[key], 0);
    return HrAppointmentSummary(
      pending: n('pending'),
      approved: n('approved'),
      rejected: n('rejected'),
      cancelled: n('cancelled'),
      completed: n('completed'),
      approvedToday: n('approvedToday'),
      upcomingVisits: n('upcomingVisits'),
      upcomingExternal: n('upcomingExternal'),
      total: n('total'),
    );
  }

  static List<HrAppointmentOption> residencesFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HrAppointmentOption(
              id: id,
              label: JsonCodec.stringOr(row['name'], 'Residence'),
            ),
      ];

  static List<HrAppointmentClient> clientsFrom(dynamic body) => [
        for (final row in JsonCodec.unwrapList(body).whereType<Map>())
          if (JsonCodec.string(row['id']) case final id?)
            HrAppointmentClient(
              id: id,
              name: [row['firstName'], row['lastName']]
                  .map((p) => JsonCodec.string(p) ?? '')
                  .where((p) => p.isNotEmpty)
                  .join(' '),
              code: JsonCodec.stringOr(row['roomNumber'], ''),
              residence: _name(JsonCodec.asMap(row), 'residence') ?? '',
              residenceId: JsonCodec.stringOr(row['residenceId'], ''),
            ),
      ];

  /// `data` is null when nothing has been written for that day.
  static List<HrAppointmentLogNote> dayLogFrom(dynamic body) {
    final data = JsonCodec.unwrap(body);
    if (data is! Map) return const [];
    return [
      for (final row in JsonCodec.listAt(JsonCodec.asMap(data), 'entries').whereType<Map>())
        _noteFrom(JsonCodec.asMap(row)),
    ];
  }

  static HrAppointmentLogNote _noteFrom(Map<String, dynamic> json) {
    final flag = JsonCodec.mapAt(json, 'flag');
    return HrAppointmentLogNote(
      id: JsonCodec.stringOr(json['id'], ''),
      body: JsonCodec.stringOr(json['body'], ''),
      logType: JsonCodec.string(json['logType']),
      openFlag: flag != null && JsonCodec.string(flag['resolvedAt']) == null,
      isSuperseded: JsonCodec.boolean(json['isSuperseded']) ?? false,
      at: JsonCodec.dateTime(json['occurredAt'] ?? json['createdAt']),
      authorName: _name(json, 'author'),
    );
  }

  static String _cell(String value) {
    if (value.contains(RegExp(r'[",\n\r]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// The register as CSV, with the web table's columns.
  static String csvFrom(List<HrAppointment> rows) {
    final buffer = StringBuffer()
      ..writeln(
        [
          'Request',
          'Residence',
          'Resident',
          'Requested By',
          'Relationship',
          'Type',
          'Date',
          'Time',
          'Location',
          'Purpose',
          'Notes',
          'Status',
          'Reviewed By',
          'Decided At',
          'Decision Reason',
        ].join(','),
      );
    for (final a in rows) {
      buffer.writeln(
        [
          a.reference,
          a.residence,
          a.client,
          a.requestedBy,
          a.relationshipLabel,
          a.typeLabel,
          a.requestedDate,
          a.time,
          a.location ?? '',
          a.purpose ?? '',
          a.notes ?? '',
          a.statusLabel,
          a.deciderName ?? '',
          a.decidedAt == null ? '' : WebFormat.dateTime(a.decidedAt),
          a.decisionReason ?? '',
        ].map(_cell).join(','),
      );
    }
    return buffer.toString();
  }
}
