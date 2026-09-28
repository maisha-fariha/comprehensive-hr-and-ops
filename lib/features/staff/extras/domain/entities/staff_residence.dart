import 'package:flutter/foundation.dart';

@immutable
class StaffResidencePerson {
  final String id;
  final String name;
  final String role;

  const StaffResidencePerson({
    required this.id,
    required this.name,
    required this.role,
  });
}

/// Residence summary/detail from `GET /residences` and `GET /residences/:id`.
@immutable
class StaffResidence {
  final String id;
  final String name;
  final String status;
  final String residenceType;
  final String serviceType;
  final String? phone;
  final String? emergencyPhone;
  final String? email;
  final String? managementPhone;
  final String? managementEmail;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final String? timezone;
  final String? notes;
  final String? operatingHours;
  final int? bedCapacity;
  final int? occupiedBeds;
  final int? availableBeds;
  final bool atCapacity;
  final int? geofenceRadiusMeters;
  final double? latitude;
  final double? longitude;
  final bool gpsTrackingEnabled;
  final int roomCount;
  final Map<String, int> careLevelMix;
  final bool outOfPocketEnabled;
  final bool mileageEnabled;
  final DateTime? updatedAt;
  final StaffResidencePerson? primaryManager;
  final StaffResidencePerson? assistantManager;
  final List<StaffResidencePerson> careTeam;
  final List<StaffResidencePerson> assignedStaff;

  const StaffResidence({
    required this.id,
    required this.name,
    required this.status,
    this.residenceType = '',
    this.serviceType = '',
    this.phone,
    this.emergencyPhone,
    this.email,
    this.managementPhone,
    this.managementEmail,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
    this.timezone,
    this.notes,
    this.operatingHours,
    this.bedCapacity,
    this.occupiedBeds,
    this.availableBeds,
    this.atCapacity = false,
    this.geofenceRadiusMeters,
    this.latitude,
    this.longitude,
    this.gpsTrackingEnabled = false,
    this.roomCount = 0,
    this.careLevelMix = const {},
    this.outOfPocketEnabled = false,
    this.mileageEnabled = false,
    this.updatedAt,
    this.primaryManager,
    this.assistantManager,
    this.careTeam = const [],
    this.assignedStaff = const [],
  });

  StaffResidence copyWith({
    String? id,
    String? name,
    String? status,
    String? residenceType,
    String? serviceType,
    String? phone,
    String? emergencyPhone,
    String? email,
    String? managementPhone,
    String? managementEmail,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? country,
    String? timezone,
    String? notes,
    String? operatingHours,
    int? bedCapacity,
    int? occupiedBeds,
    int? availableBeds,
    bool? atCapacity,
    int? geofenceRadiusMeters,
    double? latitude,
    double? longitude,
    bool? gpsTrackingEnabled,
    int? roomCount,
    Map<String, int>? careLevelMix,
    bool? outOfPocketEnabled,
    bool? mileageEnabled,
    DateTime? updatedAt,
    StaffResidencePerson? primaryManager,
    StaffResidencePerson? assistantManager,
    List<StaffResidencePerson>? careTeam,
    List<StaffResidencePerson>? assignedStaff,
  }) {
    return StaffResidence(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      residenceType: residenceType ?? this.residenceType,
      serviceType: serviceType ?? this.serviceType,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      email: email ?? this.email,
      managementPhone: managementPhone ?? this.managementPhone,
      managementEmail: managementEmail ?? this.managementEmail,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      stateProvince: stateProvince ?? this.stateProvince,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      notes: notes ?? this.notes,
      operatingHours: operatingHours ?? this.operatingHours,
      bedCapacity: bedCapacity ?? this.bedCapacity,
      occupiedBeds: occupiedBeds ?? this.occupiedBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      atCapacity: atCapacity ?? this.atCapacity,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsTrackingEnabled: gpsTrackingEnabled ?? this.gpsTrackingEnabled,
      roomCount: roomCount ?? this.roomCount,
      careLevelMix: careLevelMix ?? this.careLevelMix,
      outOfPocketEnabled: outOfPocketEnabled ?? this.outOfPocketEnabled,
      mileageEnabled: mileageEnabled ?? this.mileageEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
      primaryManager: primaryManager ?? this.primaryManager,
      assistantManager: assistantManager ?? this.assistantManager,
      careTeam: careTeam ?? this.careTeam,
      assignedStaff: assignedStaff ?? this.assignedStaff,
    );
  }

  String get formattedAddress {
    final parts = <String>[
      if ((addressLine1 ?? '').trim().isNotEmpty) addressLine1!.trim(),
      if ((addressLine2 ?? '').trim().isNotEmpty) addressLine2!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((stateProvince ?? '').trim().isNotEmpty) stateProvince!.trim(),
      if ((postalCode ?? '').trim().isNotEmpty) postalCode!.trim(),
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }

  /// Web Residences table / detail address omits country.
  String get listAddress {
    final parts = <String>[
      if ((addressLine1 ?? '').trim().isNotEmpty) addressLine1!.trim(),
      if ((addressLine2 ?? '').trim().isNotEmpty) addressLine2!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((stateProvince ?? '').trim().isNotEmpty) stateProvince!.trim(),
      if ((postalCode ?? '').trim().isNotEmpty) postalCode!.trim(),
    ];
    return parts.join(', ');
  }

  String get locationShort {
    final parts = <String>[
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((stateProvince ?? '').trim().isNotEmpty) stateProvince!.trim(),
    ];
    return parts.join(', ');
  }

  String get occupancyShort {
    final occupied = occupiedBeds;
    final capacity = bedCapacity;
    if (occupied == null && capacity == null) return '—';
    if (occupied != null && capacity != null) return '$occupied / $capacity';
    if (capacity != null) return '$capacity';
    return '$occupied';
  }

  String get capacityLabel {
    final base = occupancyShort;
    if (base == '—') return base;
    return '$base Beds';
  }

  String get typePrimaryLabel {
    final raw = residenceType.trim();
    if (raw.isEmpty) return '—';
    return raw;
  }

  String get typeSecondaryLabel => serviceType.trim();

  String get typeDisplayLabel {
    final raw = residenceType.trim().replaceAll('_', ' ');
    if (raw.isEmpty) return '—';
    return raw
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  String get typeLabel {
    final primary = typePrimaryLabel;
    final secondary = typeSecondaryLabel;
    if (primary == '—' && secondary.isEmpty) return '—';
    if (secondary.isEmpty) return primary;
    if (primary == '—') return secondary;
    return '$primary / $secondary';
  }

  String get gpsRadiusLabel {
    final meters = geofenceRadiusMeters;
    if (meters == null || meters <= 0) return '—';
    return '${meters}m';
  }

  int get totalStaffCount {
    final ids = <String>{};
    void add(StaffResidencePerson? person) {
      if (person == null) return;
      final key = person.id.trim().isNotEmpty
          ? person.id.trim()
          : person.name.trim().toLowerCase();
      if (key.isNotEmpty) ids.add(key);
    }

    add(primaryManager);
    add(assistantManager);
    for (final person in careTeam) {
      add(person);
    }
    for (final person in assignedStaff) {
      add(person);
    }
    return ids.length;
  }

  String get assignedStaffLabel {
    final count = totalStaffCount;
    if (count == 0) return '—';
    return '$count Member${count == 1 ? '' : 's'}';
  }

  String get statusLabel {
    final raw = status.trim();
    if (raw.isEmpty) return '—';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  bool get isActive => status.trim().toLowerCase() == 'active';

  String get shortId {
    final raw = id.trim();
    if (raw.length <= 8) return raw;
    return raw.substring(0, 8);
  }
}
