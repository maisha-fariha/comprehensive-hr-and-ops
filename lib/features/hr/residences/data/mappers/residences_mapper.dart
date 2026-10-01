import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/residence_detail_tabs.dart';
import '../../domain/entities/residence_summary.dart';

abstract final class ResidencesMapper {
  static List<ResidenceSummary> residencesFrom(List<dynamic> rows) {
    final items = <ResidenceSummary>[];
    for (final row in rows) {
      final residence = residenceFrom(row);
      if (residence != null) items.add(residence);
    }
    return items;
  }

  static ResidencesPageData pageFrom(dynamic body) {
    final items = residencesFrom(JsonCodec.unwrapList(body));
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final summary = JsonCodec.mapAt(meta, 'summary');
    return ResidencesPageData(
      items: items,
      total: JsonCodec.integerOr(meta['total'], items.length),
      totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
      summary: summary == null
          ? null
          : ResidencesKpis(
              residences: JsonCodec.integerOr(summary['residences'], 0),
              active: JsonCodec.integerOr(summary['active'], 0),
              residents: JsonCodec.integerOr(summary['residents'], 0),
              beds: JsonCodec.integerOr(summary['beds'], 0),
              bedsFree: JsonCodec.integerOr(summary['bedsFree'], 0),
              atCapacity: JsonCodec.integerOr(summary['atCapacity'], 0),
            ),
    );
  }

  static ResidenceSummary? residenceFrom(dynamic row) {
    final json = JsonCodec.asMap(row);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final payroll = JsonCodec.mapAt(json, 'payrollSettings');
    final mix = <String, int>{};
    final rawMix = json['careLevelMix'];
    if (rawMix is Map) {
      for (final entry in rawMix.entries) {
        final count = JsonCodec.integer(entry.value);
        if (count != null) mix['${entry.key}'] = count;
      }
    }
    return ResidenceSummary(
      id: id,
      name: JsonCodec.stringOr(json['name'], 'Unnamed residence'),
      residenceType: JsonCodec.string(json['residenceType'] ?? json['type']),
      status: JsonCodec.stringOr(json['status'], '').toLowerCase(),
      address: _address(json),
      phone: JsonCodec.string(json['phone']),
      email: JsonCodec.string(json['email']),
      timezone: JsonCodec.string(json['timezone']),
      notes: JsonCodec.string(json['notes']),
      bedCapacity: JsonCodec.integerOr(json['bedCapacity'], 0),
      residents: JsonCodec.integerOr(json['occupiedBeds'], 0),
      latitude: JsonCodec.number(json['latitude'])?.toDouble(),
      longitude: JsonCodec.number(json['longitude'])?.toDouble(),
      gpsRadiusMeters: _gpsRadius(json),
      emergencyPhone: JsonCodec.string(json['emergencyPhone']),
      addressLine1: JsonCodec.string(json['addressLine1']),
      city: JsonCodec.string(json['city']),
      stateProvince: JsonCodec.string(json['stateProvince']),
      postalCode: JsonCodec.string(json['postalCode']),
      country: JsonCodec.string(json['country']),
      serviceType: JsonCodec.string(json['serviceType']),
      operatingHours: json['operatingHours'] is String
          ? JsonCodec.string(json['operatingHours'])
          : null,
      initialOccupiedBeds: JsonCodec.integer(json['initialOccupiedBeds']),
      availableBeds: JsonCodec.integer(json['availableBeds']),
      occupancySource: JsonCodec.string(json['occupancySource']),
      atCapacityFlag: JsonCodec.boolean(json['atCapacity']),
      careLevelMix: mix,
      roomCount: JsonCodec.integerOr(json['roomCount'], 0),
      roomBedsFree: JsonCodec.integerOr(json['roomBedsFree'], 0),
      primaryManager: _person(json['primaryManager']),
      assistantManager: _person(json['assistantManager']),
      careTeam: _people(json['careTeam']),
      assignedStaff: _people(json['assignedStaff']),
      managementPhone: JsonCodec.string(json['managementPhone']),
      managementEmail: JsonCodec.string(json['managementEmail']),
      outOfPocketEnabled: payroll == null
          ? null
          : JsonCodec.boolean(payroll['outOfPocketEnabled']) ?? false,
      mileageEnabled: payroll == null
          ? null
          : JsonCodec.boolean(payroll['mileageEnabled']) ?? false,
      updatedAt: JsonCodec.dateTime(json['updatedAt']),
    );
  }

  static List<ResidenceRoom> roomsFrom(dynamic body) => roomBoardFrom(body).rooms;

  static ResidenceRoomBoard roomBoardFrom(dynamic body) {
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
    final summary = JsonCodec.mapAt(
          JsonCodec.metaOf(body) ?? const <String, dynamic>{},
          'summary',
        ) ??
        const <String, dynamic>{};
    return ResidenceRoomBoard(
      rooms: rooms,
      roomCount: JsonCodec.integerOr(summary['rooms'], 0),
      beds: JsonCodec.integerOr(summary['beds'], 0),
      occupied: JsonCodec.integerOr(summary['occupied'], 0),
      available: JsonCodec.integerOr(summary['available'], 0),
    );
  }

  static ResidenceTabPage<ResidenceResident, ResidentsSummary> residentsFrom(
    dynamic body,
  ) {
    final items = <ResidenceResident>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      items.add(
        ResidenceResident(
          id: id,
          name: _fullName(json),
          initials: _initials(json),
          level: JsonCodec.string(json['level']),
          roomNumber: JsonCodec.string(json['roomNumber']),
          dateOfBirth: JsonCodec.dateTime(json['dateOfBirth']),
          admissionDate: JsonCodec.dateTime(json['admissionDate']),
          statusLabel: _humanise(JsonCodec.stringOr(json['status'], '')),
        ),
      );
    }
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final summary = JsonCodec.mapAt(meta, 'summary');
    return ResidenceTabPage(
      items: items,
      total: JsonCodec.integerOr(meta['total'], items.length),
      summary: summary == null
          ? null
          : ResidentsSummary(
              clients: JsonCodec.integerOr(summary['clients'], 0),
              active: JsonCodec.integerOr(summary['active'], 0),
              onLeave: JsonCodec.integerOr(summary['onLeave'], 0),
              unrated: JsonCodec.integerOr(summary['unrated'], 0),
            ),
    );
  }

  static ResidenceTabPage<ResidenceStaffMember, StaffSummary> staffFrom(
    dynamic body,
  ) {
    final items = <ResidenceStaffMember>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      final employment = JsonCodec.string(json['employmentType']);
      items.add(
        ResidenceStaffMember(
          id: id,
          name: _fullName(json),
          initials: _initials(json),
          employeeCode: JsonCodec.stringOr(json['employeeCode'], '—'),
          category: JsonCodec.stringOr(
            JsonCodec.mapAt(json, 'category')?['name'],
            '—',
          ),
          employmentType: employment == null ? '—' : _humanise(employment),
          medAdminCertified:
              JsonCodec.boolean(json['medAdminCertified']) ?? false,
          statusLabel: _humanise(JsonCodec.stringOr(json['status'], '')),
        ),
      );
    }
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    final summary = JsonCodec.mapAt(meta, 'summary');
    return ResidenceTabPage(
      items: items,
      total: JsonCodec.integerOr(meta['total'], items.length),
      summary: summary == null
          ? null
          : StaffSummary(
              staff: JsonCodec.integerOr(summary['staff'], 0),
              active: JsonCodec.integerOr(summary['active'], 0),
              onLeave: JsonCodec.integerOr(summary['onLeave'], 0),
              medAdminCertified:
                  JsonCodec.integerOr(summary['medAdminCertified'], 0),
            ),
    );
  }

  static List<ResidenceStaffOption> staffOptionsFrom(dynamic body) {
    final options = <ResidenceStaffOption>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      options.add(ResidenceStaffOption(id: id, label: _fullName(json)));
    }
    return options;
  }

  static List<ResidenceShift> shiftsFrom(dynamic body) {
    final shifts = <ResidenceShift>[];
    for (final row in JsonCodec.unwrapList(body)) {
      final json = JsonCodec.asMap(row);
      final id = JsonCodec.string(json['id']);
      if (id == null) continue;
      shifts.add(
        ResidenceShift(
          id: id,
          title: JsonCodec.string(json['title']),
          shiftType: JsonCodec.string(json['shiftType']),
          status: JsonCodec.string(json['status']),
          startsAt: JsonCodec.dateTime(json['startsAt']),
          endsAt: JsonCodec.dateTime(json['endsAt']),
          assignedCount: JsonCodec.integerOr(json['assignedCount'], 0),
          requiredStaffCount:
              JsonCodec.integerOr(json['requiredStaffCount'], 1),
          requiredCategoryName: JsonCodec.string(json['requiredCategoryName']),
        ),
      );
    }
    return shifts;
  }

  static ResidenceTabPage<ResidenceLogDay, void> logDaysFrom(dynamic body) {
    final items = <ResidenceLogDay>[
      for (final row in JsonCodec.unwrapList(body))
        () {
          final json = JsonCodec.asMap(row);
          return ResidenceLogDay(
            clientName: JsonCodec.stringOr(json['clientName'], '—'),
            logDate: JsonCodec.dateTime(json['logDate']),
            entriesCount: JsonCodec.integerOr(json['entriesCount'], 0),
          );
        }(),
    ];
    final meta = JsonCodec.metaOf(body) ?? const <String, dynamic>{};
    return ResidenceTabPage(
      items: items,
      total: JsonCodec.integerOr(meta['total'], items.length),
    );
  }

  static ResidenceTenantContext tenantContextFrom(dynamic body) {
    final me = JsonCodec.unwrapMap(body);
    final tenant = JsonCodec.mapAt(me, 'tenant') ?? const <String, dynamic>{};
    final limits = JsonCodec.mapAt(tenant, 'limits') ?? const <String, dynamic>{};
    return ResidenceTenantContext(
      residenceLimit: JsonCodec.integer(limits['residences']),
      enabledResidenceTypes: [
        for (final t in JsonCodec.listAt(tenant, 'enabledResidenceTypes'))
          if (JsonCodec.string(t) != null) JsonCodec.string(t)!,
      ],
    );
  }

  /// Web `formatAddress`: line 1, line 2, city, state, postal code.
  static String? _address(Map<String, dynamic> json) {
    final parts = [
      json['addressLine1'],
      json['addressLine2'],
      json['city'],
      json['stateProvince'],
      json['postalCode'],
    ].map(JsonCodec.string).whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static int? _gpsRadius(Map<String, dynamic> json) {
    final geofence = json['geofence'];
    if (geofence is Map) {
      return JsonCodec.integer(JsonCodec.asMap(geofence)['radiusMeters']);
    }
    return null;
  }

  static ResidencePerson? _person(dynamic value) {
    if (value is! Map) return null;
    final json = JsonCodec.asMap(value);
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return ResidencePerson(
      id: id,
      name: JsonCodec.stringOr(json['name'], 'Unknown'),
      role: JsonCodec.string(json['role']),
    );
  }

  static List<ResidencePerson> _people(dynamic value) {
    if (value is! List) return const [];
    return value.map(_person).whereType<ResidencePerson>().toList();
  }

  static String _fullName(Map<String, dynamic> json) {
    final name = [
      JsonCodec.string(json['firstName']),
      JsonCodec.string(json['lastName']),
    ].whereType<String>().join(' ');
    return name.isEmpty
        ? JsonCodec.stringOr(json['fullName'] ?? json['name'], 'Unnamed')
        : name;
  }

  static String _initials(Map<String, dynamic> json) {
    String first(dynamic v) {
      final s = JsonCodec.string(v);
      return s == null ? '' : s[0];
    }

    final initials =
        '${first(json['firstName'])}${first(json['lastName'])}'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  static String _humanise(String value) {
    final spaced = value.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return '';
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
