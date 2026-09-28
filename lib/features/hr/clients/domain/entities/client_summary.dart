import 'package:flutter/foundation.dart';

/// A resident from `GET /clients` (and `GET /clients/{id}` for [transfers]).
@immutable
class ClientSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? residenceId;
  final String? residenceName;
  final String? room;
  final String? careLevel;
  final String status;
  final DateTime? dateOfBirth;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> carePlanGoals;
  final int? reviewCycleDays;
  final List<ClientTransfer> transfers;

  const ClientSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.photoUrl,
    this.residenceId,
    this.residenceName,
    this.room,
    this.careLevel,
    this.dateOfBirth,
    this.allergies = const [],
    this.conditions = const [],
    this.carePlanGoals = const [],
    this.reviewCycleDays,
    this.transfers = const [],
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Unnamed client' : name;
  }

  String get initials {
    final parts = [firstName, lastName].where((p) => p.isNotEmpty);
    final letters = parts.map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  /// Short display id, e.g. `#A1F320`.
  String get shortId {
    final compact = id.replaceAll('-', '').toUpperCase();
    return '#${compact.length <= 6 ? compact : compact.substring(0, 6)}';
  }

  bool get isActive => status.toLowerCase() == 'active';

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }
}

@immutable
class ClientTransfer {
  final String? fromResidenceId;
  final String? toResidenceId;
  final DateTime? transferredAt;
  final String? reason;

  const ClientTransfer({
    this.fromResidenceId,
    this.toResidenceId,
    this.transferredAt,
    this.reason,
  });
}
