import 'package:flutter/foundation.dart';

/// A home from `GET /residences`, enriched with its resident count.
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
  final int residents;
  final double? latitude;
  final double? longitude;
  final int? gpsRadiusMeters;

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
  });

  bool get isActive => status.toLowerCase() == 'active';

  int get bedsFree => (bedCapacity - residents).clamp(0, bedCapacity);

  bool get atCapacity => bedCapacity > 0 && residents >= bedCapacity;

  String get statusLabel => status.isEmpty
      ? 'Unknown'
      : '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}';
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
