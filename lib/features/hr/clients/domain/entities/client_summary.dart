import 'package:flutter/foundation.dart';

/// A resident from `GET /clients` (and `GET /clients/{id}` for [transfers]).
@immutable
class ClientSummary {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? photoUrl;
  final String? residenceId;
  final String? residenceName;

  /// Display room: the room name, else the free-text `roomNumber`.
  final String? room;
  final String? roomId;
  final String? roomNumber;

  /// API `level` (`Low` / `Medium` / `High`).
  final String? careLevel;

  /// Raw API status (`Active`, `active`, `Pending`, ...).
  final String status;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final String? gender;
  final String? fundingSource;
  final Map<String, bool> portalVisibility;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> diagnoses;
  final List<String> currentMedications;
  final String doctorName;
  final String pharmacyName;
  final String behavioralTriggers;
  final String safetyPlanNotes;
  final List<String> carePlanGoals;
  final List<String> outcomes;
  final String servicePlan;
  final String progressNotes;
  final String assignmentNotes;
  final String contactNotes;
  final int? reviewCycleDays;
  final List<ClientTransfer> transfers;

  const ClientSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.middleName,
    this.photoUrl,
    this.residenceId,
    this.residenceName,
    this.room,
    this.roomId,
    this.roomNumber,
    this.careLevel,
    this.dateOfBirth,
    this.admissionDate,
    this.gender,
    this.fundingSource,
    this.portalVisibility = const {},
    this.allergies = const [],
    this.conditions = const [],
    this.diagnoses = const [],
    this.currentMedications = const [],
    this.doctorName = '',
    this.pharmacyName = '',
    this.behavioralTriggers = '',
    this.safetyPlanNotes = '',
    this.carePlanGoals = const [],
    this.outcomes = const [],
    this.servicePlan = '',
    this.progressNotes = '',
    this.assignmentNotes = '',
    this.contactNotes = '',
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

  /// The web's short id: the first 8 characters of the UUID.
  String get shortId => id.length <= 8 ? id : id.substring(0, 8);

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

/// A row of `GET /clients/deleted` (the web "Deleted residents" log).
@immutable
class DeletedClient {
  final ClientSummary client;
  final DateTime? deletedAt;
  final String? deletedByName;
  final String? reason;
  final String? statusBeforeDelete;

  const DeletedClient({
    required this.client,
    this.deletedAt,
    this.deletedByName,
    this.reason,
    this.statusBeforeDelete,
  });
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
