import 'package:flutter/foundation.dart';

/// A person attached to a residence (`primaryManager`, `careTeam[]`, ...).
@immutable
class ResidencePerson {
  final String id;
  final String name;
  final String? role;

  const ResidencePerson({required this.id, required this.name, this.role});
}

/// A home from `GET /residences` / `GET /residences/{id}`.
@immutable
class ResidenceSummary {
  final String id;
  final String name;
  final String? residenceType;
  final String status;
  final String? address;
  final String? phone;
  final String? email;
  final String? timezone;
  final String? notes;
  final int bedCapacity;

  /// `occupiedBeds` from the API.
  final int residents;
  final double? latitude;
  final double? longitude;
  final int? gpsRadiusMeters;
  final String? emergencyPhone;
  final String? addressLine1;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final String? serviceType;
  final String? operatingHours;
  final int? initialOccupiedBeds;
  final int? availableBeds;
  final String? occupancySource;
  final bool? atCapacityFlag;
  final Map<String, int> careLevelMix;
  final int roomCount;
  final int roomBedsFree;
  final ResidencePerson? primaryManager;
  final ResidencePerson? assistantManager;
  final List<ResidencePerson> careTeam;
  final List<ResidencePerson> assignedStaff;
  final String? managementPhone;
  final String? managementEmail;

  /// `null` when the API sent no `payrollSettings`.
  final bool? outOfPocketEnabled;
  final bool? mileageEnabled;
  final DateTime? updatedAt;

  const ResidenceSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.bedCapacity,
    required this.residents,
    this.residenceType,
    this.address,
    this.phone,
    this.email,
    this.timezone,
    this.notes,
    this.latitude,
    this.longitude,
    this.gpsRadiusMeters,
    this.emergencyPhone,
    this.addressLine1,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
    this.serviceType,
    this.operatingHours,
    this.initialOccupiedBeds,
    this.availableBeds,
    this.occupancySource,
    this.atCapacityFlag,
    this.careLevelMix = const {},
    this.roomCount = 0,
    this.roomBedsFree = 0,
    this.primaryManager,
    this.assistantManager,
    this.careTeam = const [],
    this.assignedStaff = const [],
    this.managementPhone,
    this.managementEmail,
    this.outOfPocketEnabled,
    this.mileageEnabled,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';

  int get bedsFree =>
      availableBeds ?? (bedCapacity - residents).clamp(0, bedCapacity);

  bool get atCapacity =>
      atCapacityFlag ?? (bedCapacity > 0 && residents >= bedCapacity);

  /// The web "Near Capacity" pill: 85% or more but not full.
  bool get nearCapacity =>
      !atCapacity && bedCapacity > 0 && residents / bedCapacity * 100 >= 85;

  /// Web `toResidenceRow().assignedStaff`.
  int get assignedStaffCount =>
      (primaryManager == null ? 0 : 1) +
      (assistantManager == null ? 0 : 1) +
      careTeam.length +
      assignedStaff.length;

  bool get hasPayrollSettings =>
      outOfPocketEnabled != null || mileageEnabled != null;

  String get statusLabel => status.isEmpty
      ? 'Unknown'
      : '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}';

  ResidenceSummary copyWith({
    String? status,
    bool? outOfPocketEnabled,
    bool? mileageEnabled,
  }) {
    return ResidenceSummary(
      id: id,
      name: name,
      status: status ?? this.status,
      bedCapacity: bedCapacity,
      residents: residents,
      residenceType: residenceType,
      address: address,
      phone: phone,
      email: email,
      timezone: timezone,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      gpsRadiusMeters: gpsRadiusMeters,
      emergencyPhone: emergencyPhone,
      addressLine1: addressLine1,
      city: city,
      stateProvince: stateProvince,
      postalCode: postalCode,
      country: country,
      serviceType: serviceType,
      operatingHours: operatingHours,
      initialOccupiedBeds: initialOccupiedBeds,
      availableBeds: availableBeds,
      occupancySource: occupancySource,
      atCapacityFlag: atCapacityFlag,
      careLevelMix: careLevelMix,
      roomCount: roomCount,
      roomBedsFree: roomBedsFree,
      primaryManager: primaryManager,
      assistantManager: assistantManager,
      careTeam: careTeam,
      assignedStaff: assignedStaff,
      managementPhone: managementPhone,
      managementEmail: managementEmail,
      outOfPocketEnabled: outOfPocketEnabled ?? this.outOfPocketEnabled,
      mileageEnabled: mileageEnabled ?? this.mileageEnabled,
      updatedAt: updatedAt,
    );
  }
}

/// `meta.summary` of `GET /residences` — the four KPI tiles.
@immutable
class ResidencesKpis {
  final int residences;
  final int active;
  final int residents;
  final int beds;
  final int bedsFree;
  final int atCapacity;

  const ResidencesKpis({
    this.residences = 0,
    this.active = 0,
    this.residents = 0,
    this.beds = 0,
    this.bedsFree = 0,
    this.atCapacity = 0,
  });
}

/// One page of `GET /residences`.
@immutable
class ResidencesPageData {
  final List<ResidenceSummary> items;
  final int total;
  final int totalPages;
  final ResidencesKpis? summary;

  const ResidencesPageData({
    required this.items,
    required this.total,
    required this.totalPages,
    this.summary,
  });
}

/// One room from `GET /residences/{id}/rooms`.
@immutable
class ResidenceRoom {
  final String id;
  final String name;
  final String? floor;
  final String? wing;
  final String? roomType;
  final int capacity;
  final int occupied;
  final bool isActive;
  final List<String> residentNames;

  const ResidenceRoom({
    required this.id,
    required this.name,
    required this.capacity,
    required this.occupied,
    required this.isActive,
    required this.residentNames,
    this.floor,
    this.wing,
    this.roomType,
  });

  int get available => (capacity - occupied).clamp(0, capacity);
}

/// `GET /residences/{id}/rooms` with its `meta.summary`.
@immutable
class ResidenceRoomBoard {
  final List<ResidenceRoom> rooms;
  final int roomCount;
  final int beds;
  final int occupied;
  final int available;

  const ResidenceRoomBoard({
    required this.rooms,
    this.roomCount = 0,
    this.beds = 0,
    this.occupied = 0,
    this.available = 0,
  });
}

/// Tenant context from `GET /auth/me`: plan limit and enabled home types.
@immutable
class ResidenceTenantContext {
  final int? residenceLimit;
  final List<String> enabledResidenceTypes;

  const ResidenceTenantContext({
    this.residenceLimit,
    this.enabledResidenceTypes = const [],
  });
}

/// A staff member for the wizard pickers (`GET /staff`).
@immutable
class ResidenceStaffOption {
  final String id;
  final String label;

  const ResidenceStaffOption({required this.id, required this.label});
}
