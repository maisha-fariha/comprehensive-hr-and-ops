import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_residence.dart';

abstract final class StaffExtrasMapper {
  static StaffResidencePerson? _personFrom(dynamic raw) {
    final json = JsonCodec.asMap(raw);
    final name = JsonCodec.stringOr(json['name'], '').trim();
    if (name.isEmpty) return null;
    return StaffResidencePerson(
      id: JsonCodec.stringOr(json['id'], name),
      name: name,
      role: JsonCodec.stringOr(json['role'], ''),
    );
  }

  static List<StaffResidencePerson> _peopleFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(_personFrom)
        .whereType<StaffResidencePerson>()
        .toList(growable: false);
  }

  static StaffResidence residenceFrom(dynamic body) {
    final json = unwrap(body);
    final geofence = JsonCodec.mapAt(json, 'geofence');
    final payroll = JsonCodec.mapAt(json, 'payrollSettings');
    final mixRaw = JsonCodec.mapAt(json, 'careLevelMix') ?? const {};
    final careLevelMix = <String, int>{};
    mixRaw.forEach((key, value) {
      final count = JsonCodec.integer(value);
      if (count != null && key.trim().isNotEmpty) {
        careLevelMix[key.trim()] = count;
      }
    });
    return StaffResidence(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(json['name'] ?? json['title'], 'Residence')
          .trim(),
      status: JsonCodec.stringOr(json['status'] ?? json['state'], ''),
      residenceType: JsonCodec.stringOr(json['residenceType'], ''),
      serviceType: JsonCodec.stringOr(json['serviceType'], ''),
      phone: JsonCodec.string(json['phone']),
      emergencyPhone: JsonCodec.string(json['emergencyPhone']),
      email: JsonCodec.string(json['email']),
      managementPhone: JsonCodec.string(json['managementPhone']),
      managementEmail: JsonCodec.string(json['managementEmail']),
      addressLine1: JsonCodec.string(json['addressLine1']),
      addressLine2: JsonCodec.string(json['addressLine2']),
      city: JsonCodec.string(json['city']),
      stateProvince: JsonCodec.string(json['stateProvince']),
      postalCode: JsonCodec.string(json['postalCode']),
      country: JsonCodec.string(json['country']),
      timezone: JsonCodec.string(json['timezone']),
      notes: JsonCodec.string(json['notes']),
      operatingHours: JsonCodec.string(json['operatingHours']),
      bedCapacity: JsonCodec.integer(json['bedCapacity']),
      occupiedBeds: JsonCodec.integer(json['occupiedBeds']),
      availableBeds: JsonCodec.integer(json['availableBeds']),
      atCapacity: JsonCodec.boolean(json['atCapacity']) ?? false,
      geofenceRadiusMeters: JsonCodec.integer(
        geofence?['radiusMeters'] ?? json['gpsRadiusMeters'],
      ),
      latitude: JsonCodec.number(json['latitude'])?.toDouble(),
      longitude: JsonCodec.number(json['longitude'])?.toDouble(),
      gpsTrackingEnabled: JsonCodec.boolean(geofence?['enabled']) ??
          (JsonCodec.integer(geofence?['radiusMeters']) ?? 0) > 0,
      roomCount: JsonCodec.integerOr(json['roomCount'], 0),
      careLevelMix: careLevelMix,
      outOfPocketEnabled:
          JsonCodec.boolean(payroll?['outOfPocketEnabled']) ?? false,
      mileageEnabled: JsonCodec.boolean(payroll?['mileageEnabled']) ?? false,
      updatedAt: JsonCodec.dateTime(json['updatedAt']),
      primaryManager: _personFrom(json['primaryManager']),
      assistantManager: _personFrom(json['assistantManager']),
      careTeam: _peopleFrom(json['careTeam']),
      assignedStaff: _peopleFrom(json['assignedStaff']),
    );
  }

  static List<StaffResidence> residencesFrom(dynamic body) {
    return JsonCodec.unwrapList(body)
        .map(residenceFrom)
        .where((item) => item.id.isNotEmpty || item.name.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, String>> rowsFrom(
    dynamic body, {
    required String titleKeys,
    String subtitleKeys = 'status,description,notes,summary,type',
  }) {
    final titleCandidates = titleKeys.split(',');
    final subtitleCandidates = subtitleKeys.split(',');

    return JsonCodec.unwrapList(body).whereType<Map>().map((item) {
      final json = JsonCodec.asMap(item);
      var title = 'Item';
      for (final key in titleCandidates) {
        final value = JsonCodec.string(json[key.trim()]);
        if (value != null && value.isNotEmpty) {
          title = value;
          break;
        }
      }
      var subtitle = '';
      for (final key in subtitleCandidates) {
        final raw = json[key.trim()];
        final value = JsonCodec.string(raw) ??
            (raw == null ? null : raw.toString().trim());
        if (value != null && value.isNotEmpty && value != 'null') {
          subtitle = value;
          break;
        }
      }
      final at = JsonCodec.dateTime(
        json['createdAt'] ?? json['activityDate'] ?? json['updatedAt'],
      );
      if (subtitle.isEmpty && at != null) {
        subtitle = IsoDateRange.formatDisplayDate(at.toLocal());
      }
      return {
        'id': JsonCodec.stringOr(json['id'], title),
        'title': title,
        'subtitle': subtitle,
        'status': JsonCodec.stringOr(json['status'] ?? json['state'], ''),
        'clientId': JsonCodec.stringOr(json['clientId'], ''),
        'courseId': JsonCodec.stringOr(
          json['courseId'] ?? JsonCodec.mapAt(json, 'course')?['id'],
          '',
        ),
      };
    }).toList();
  }

  static Map<String, dynamic> unwrap(dynamic body) => JsonCodec.unwrapMap(body);

  const StaffExtrasMapper._();
}
