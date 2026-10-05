import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/client_extras.dart';
import '../../domain/entities/client_summary.dart';

abstract final class ClientsMapper {
  static List<ClientSummary> clientsFrom(List<dynamic> rows) {
    final items = <ClientSummary>[];
    for (final row in rows) {
      final client = clientFrom(row);
      if (client != null) items.add(client);
    }
    return items;
  }

  static ClientPage pageFrom(dynamic body, {required int limit}) {
    final items = clientsFrom(JsonCodec.unwrapList(body));
    final meta = JsonCodec.metaOf(body) ?? const {};
    final total = JsonCodec.integer(meta['total']) ?? items.length;
    final pages = JsonCodec.integer(meta['totalPages']) ??
        (limit <= 0 ? 1 : (total + limit - 1) ~/ limit);
    return ClientPage(items: items, total: total, totalPages: pages);
  }

  static ClientSummary? clientFrom(dynamic body) {
    final json = JsonCodec.asMap(body);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final residence = JsonCodec.mapAt(json, 'residence');
    final room = JsonCodec.mapAt(json, 'room');
    final carePlan = JsonCodec.mapAt(json, 'carePlan') ?? const {};
    final medical = JsonCodec.mapAt(json, 'medicalInfo') ?? const {};
    final roomNumber = JsonCodec.string(json['roomNumber']);

    return ClientSummary(
      id: id,
      firstName: JsonCodec.stringOr(json['firstName'], ''),
      lastName: JsonCodec.stringOr(json['lastName'], ''),
      photoUrl: _photoUrl(json),
      residenceId: JsonCodec.string(json['residenceId'] ?? residence?['id']),
      residenceName: JsonCodec.string(residence?['name'] ?? json['residenceName']),
      room: JsonCodec.string(room?['name']) ??
          roomNumber ??
          JsonCodec.string(json['roomName']),
      roomId: JsonCodec.string(json['roomId'] ?? room?['id']),
      roomNumber: roomNumber,
      careLevel: JsonCodec.string(json['level'] ?? json['careLevel']),
      status: JsonCodec.stringOr(json['status'], ''),
      dateOfBirth: JsonCodec.dateTime(json['dateOfBirth']),
      admissionDate: JsonCodec.dateTime(json['admissionDate']),
      gender: JsonCodec.string(json['gender']),
      fundingSource: JsonCodec.string(json['fundingSource']),
      portalVisibility: _flags(json['portalVisibility']),
      allergies: _strings(medical['allergies']),
      conditions: _strings(medical['conditions']),
      diagnoses: _strings(medical['diagnoses']),
      currentMedications: _strings(medical['currentMedications']),
      doctorName: _text(medical['doctorName']),
      pharmacyName: _text(medical['pharmacyName']),
      behavioralTriggers: _text(medical['behavioralTriggers']),
      safetyPlanNotes: _text(medical['safetyPlanNotes']),
      carePlanGoals: _strings(carePlan['goals']),
      outcomes: _strings(carePlan['outcomes']),
      servicePlan: _text(carePlan['servicePlan']),
      progressNotes: _text(carePlan['progressNotes']),
      assignmentNotes: _text(carePlan['assignmentNotes']),
      contactNotes: _text(carePlan['contactNotes']),
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

  /// `data.tenant.limits.clients` from `GET /auth/me`.
  static int? clientLimitFrom(dynamic body) {
    final tenant = JsonCodec.mapAt(JsonCodec.unwrapMap(body), 'tenant');
    final limits = tenant == null ? null : JsonCodec.mapAt(tenant, 'limits');
    return limits == null ? null : JsonCodec.integer(limits['clients']);
  }

  static List<ClientFamilyMember> familyFrom(dynamic body) {
    final items = <ClientFamilyMember>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      items.add(
        ClientFamilyMember(
          id: id,
          name: JsonCodec.stringOr(json['name'], ''),
          userId: JsonCodec.string(json['userId']),
          relationship: JsonCodec.string(json['relationship']),
          email: JsonCodec.string(json['email']),
          phone: JsonCodec.string(json['phone']),
          isPrimaryGuardian: JsonCodec.boolean(json['isPrimaryGuardian']) ?? false,
          isEmergencyContact:
              JsonCodec.boolean(json['isEmergencyContact']) ?? false,
          receiveNotifications:
              JsonCodec.boolean(json['receiveNotifications']) ?? false,
          emergencyAlerts: JsonCodec.boolean(json['emergencyAlerts']) ?? false,
        ),
      );
    }
    return items;
  }

  static List<ClientRoom> roomsFrom(dynamic body) {
    final items = <ClientRoom>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      items.add(
        ClientRoom(
          id: id,
          name: JsonCodec.stringOr(json['name'], 'Room'),
          roomType: JsonCodec.string(json['roomType']),
          isActive: JsonCodec.boolean(json['isActive']) ?? true,
          available: JsonCodec.integerOr(json['available'], 0),
        ),
      );
    }
    return items;
  }

  static ClientSpend spendFrom(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    return ClientSpend(
      spend: JsonCodec.number(json['spend']),
      purchaseCount: JsonCodec.integerOr(json['purchaseCount'], 0),
      stockOnHandValue: JsonCodec.number(json['stockOnHandValue']),
      stockOnHandCount: JsonCodec.listAt(json, 'stockOnHand').length,
      unpricedStockCount: JsonCodec.integerOr(json['unpricedStockCount'], 0),
      purchases: JsonCodec.listAt(json, 'purchases').map((row) {
        final p = JsonCodec.asMap(row);
        final item = p['item'];
        return ClientPurchase(
          item: item is Map
              ? JsonCodec.stringOr(item['name'], 'Item')
              : JsonCodec.stringOr(item ?? p['itemName'], 'Item'),
          quantity: JsonCodec.number(p['quantity']) ?? 0,
          unit: JsonCodec.string(p['unit']),
          unitCost: JsonCodec.number(p['unitCost']),
          lineTotal: JsonCodec.number(p['lineTotal']),
          orderedAt: JsonCodec.dateTime(p['orderedAt']),
        );
      }).toList(),
    );
  }

  /// The web `toClientRow` photo lookup.
  static String? _photoUrl(Map<String, dynamic> json) {
    final raw = json['photoUrl'] ?? json['photo'] ?? json['avatar'] ?? json['avatarUrl'];
    if (raw is Map) {
      return JsonCodec.string(raw['fileUrl'] ?? raw['url'] ?? raw['path']);
    }
    return JsonCodec.string(raw);
  }

  static Map<String, bool> _flags(dynamic value) {
    if (value is! Map) return const {};
    final flags = <String, bool>{};
    value.forEach((key, v) {
      final b = JsonCodec.boolean(v);
      if (b != null) flags[key.toString()] = b;
    });
    return flags;
  }

  static String _text(dynamic value) => value is String ? value : '';

  static List<String> _strings(dynamic value) {
    if (value is List) {
      return value.map(JsonCodec.string).whereType<String>().toList();
    }
    final single = JsonCodec.string(value);
    return single == null ? const [] : [single];
  }
}
