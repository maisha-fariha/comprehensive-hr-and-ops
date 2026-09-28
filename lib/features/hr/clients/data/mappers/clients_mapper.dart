import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/client_summary.dart';

abstract final class ClientsMapper {
  static List<ClientSummary> clientsFrom(List<dynamic> rows) {
    final items = <ClientSummary>[];
    for (final row in rows) {
      final client = clientFrom(row);
      if (client != null) items.add(client);
    }
    items.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return items;
  }

  static ClientSummary? clientFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence');
    final room = JsonCodec.mapAt(json, 'room');
    final carePlan = JsonCodec.mapAt(json, 'carePlan') ?? const {};
    final medical = JsonCodec.mapAt(json, 'medicalInfo') ?? const {};

    return ClientSummary(
      id: id,
      firstName: JsonCodec.stringOr(json['firstName'], ''),
      lastName: JsonCodec.stringOr(json['lastName'], ''),
      photoUrl: JsonCodec.string(json['photoUrl']),
      residenceId: JsonCodec.string(json['residenceId'] ?? residence?['id']),
      residenceName: JsonCodec.string(residence?['name'] ?? json['residenceName']),
      room: JsonCodec.string(room?['name'] ?? json['roomName'] ?? json['room']),
      careLevel: JsonCodec.string(json['level'] ?? json['careLevel']),
      status: JsonCodec.stringOr(json['status'], 'active').toLowerCase(),
      dateOfBirth: JsonCodec.dateTime(json['dateOfBirth']),
      allergies: _strings(medical['allergies']),
      conditions: _strings(medical['conditions']),
      carePlanGoals: _strings(carePlan['goals']),
      reviewCycleDays: JsonCodec.integer(carePlan['reviewCycleDays']),
      transfers: JsonCodec.listAt(json, 'transfers').map((t) {
        final m = JsonCodec.asMap(t);
        return ClientTransfer(
          fromResidenceId: JsonCodec.string(m['fromResidenceId']),
          toResidenceId: JsonCodec.string(m['toResidenceId']),
          transferredAt: JsonCodec.dateTime(m['transferredAt']),
          reason: JsonCodec.string(m['reason']),
        );
      }).toList(),
    );
  }

  /// `{ id: name }` from `GET /residences`.
  static Map<String, String> residenceNamesFrom(dynamic body) {
    final names = <String, String>{};
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      final name = JsonCodec.string(json['name']);
      if (id != null && name != null) names[id] = name;
    }
    return names;
  }

  static List<String> _strings(dynamic value) {
    if (value is List) {
      return value.map(JsonCodec.string).whereType<String>().toList();
    }
    final single = JsonCodec.string(value);
    return single == null ? const [] : [single];
  }
}
