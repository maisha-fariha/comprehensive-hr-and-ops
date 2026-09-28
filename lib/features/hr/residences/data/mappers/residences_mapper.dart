import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/residence_summary.dart';

abstract final class ResidencesMapper {
  static List<ResidenceSummary> residencesFrom(
    List<dynamic> rows, {
    required Map<String, int> residentCounts,
  }) {
    final items = <ResidenceSummary>[];
    for (final row in rows) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      items.add(
        ResidenceSummary(
          id: id,
          name: JsonCodec.stringOr(json['name'], 'Unnamed residence'),
          residenceType: JsonCodec.string(json['residenceType'] ?? json['type']),
          status: JsonCodec.stringOr(json['status'], 'active').toLowerCase(),
          address: _address(json),
          phone: JsonCodec.string(json['phone']),
          email: JsonCodec.string(json['email']),
          timezone: JsonCodec.string(json['timezone']),
          notes: JsonCodec.string(json['notes']),
          bedCapacity: JsonCodec.integerOr(
            json['bedCapacity'] ?? json['capacity'],
            0,
          ),
          residents: residentCounts[id] ??
              JsonCodec.integerOr(
                json['residentCount'] ?? json['occupiedBeds'],
                0,
              ),
          latitude: JsonCodec.number(json['latitude'])?.toDouble(),
          longitude: JsonCodec.number(json['longitude'])?.toDouble(),
          gpsRadiusMeters: _gpsRadius(json),
        ),
      );
    }
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  /// Active residents per `residenceId`.
  static Map<String, int> residentCountsFrom(List<dynamic> clientRows) {
    final counts = <String, int>{};
    for (final row in clientRows) {
      final json = JsonCodec.asMap(row);
      final status = JsonCodec.string(json['status'])?.toLowerCase();
      if (status != null && status != 'active') continue;
      final residenceId = JsonCodec.string(
        json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
      );
      if (residenceId == null) continue;
      counts[residenceId] = (counts[residenceId] ?? 0) + 1;
    }
    return counts;
  }

  static List<ResidenceRoom> roomsFrom(dynamic body) {
    final rooms = <ResidenceRoom>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final residents = JsonCodec.listAt(json, 'residents')
          .map((r) {
            final m = JsonCodec.asMap(r);
            return JsonCodec.string(m['fullName']) ??
                [
                  JsonCodec.string(m['firstName']),
                  JsonCodec.string(m['lastName']),
                ].whereType<String>().join(' ');
          })
          .where((name) => name.isNotEmpty)
          .toList();
      rooms.add(
        ResidenceRoom(
          id: id,
          name: JsonCodec.stringOr(json['name'], 'Room'),
          floor: JsonCodec.string(json['floor']),
          wing: JsonCodec.string(json['wing']),
          roomType: JsonCodec.string(json['roomType']),
          capacity: JsonCodec.integerOr(json['capacity'], 0),
          occupied: JsonCodec.integerOr(json['occupied'], residents.length),
          isActive: JsonCodec.boolean(json['isActive']) ?? true,
          residentNames: residents,
        ),
      );
    }
    return rooms;
  }

  static String? _address(Map<String, dynamic> json) {
    final parts = [
      json['addressLine1'],
      json['addressLine2'],
      json['city'],
      json['stateProvince'],
      json['postalCode'],
      json['country'],
    ].map(JsonCodec.string).whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static int? _gpsRadius(Map<String, dynamic> json) {
    final geofence = json['geofence'];
    if (geofence is Map) {
      final map = JsonCodec.asMap(geofence);
      return JsonCodec.integer(
        map['radius'] ?? map['radiusMeters'] ?? map['radiusM'],
      );
    }
    return JsonCodec.integer(
      json['geofenceRadius'] ?? json['gpsRadius'] ?? json['radiusMeters'],
    );
  }
}
