import 'package:flutter/foundation.dart';

/// One page of a list shown inside the residence detail tabs.
@immutable
class ResidenceTabPage<T, S> {
  final List<T> items;
  final int total;
  final S? summary;

  const ResidenceTabPage({required this.items, required this.total, this.summary});
}

/// Clients tab row (`GET /clients?residenceId=`).
@immutable
class ResidenceResident {
  final String id;
  final String name;
  final String initials;
  final String? level;
  final String? roomNumber;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final String statusLabel;

  const ResidenceResident({
    required this.id,
    required this.name,
    required this.initials,
    required this.statusLabel,
    this.level,
    this.roomNumber,
    this.dateOfBirth,
    this.admissionDate,
  });
}

/// `meta.summary` of `GET /clients`.
@immutable
class ResidentsSummary {
  final int clients;
  final int active;
  final int onLeave;
  final int unrated;

  const ResidentsSummary({
    this.clients = 0,
    this.active = 0,
    this.onLeave = 0,
    this.unrated = 0,
  });
}

/// Staff tab row (`GET /staff?residenceId=`).
@immutable
class ResidenceStaffMember {
  final String id;
  final String name;
  final String initials;
  final String employeeCode;
  final String category;
  final String employmentType;
  final bool medAdminCertified;
  final String statusLabel;

  const ResidenceStaffMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.employeeCode,
    required this.category,
    required this.employmentType,
    required this.medAdminCertified,
    required this.statusLabel,
  });
}

/// `meta.summary` of `GET /staff`.
@immutable
class StaffSummary {
  final int staff;
  final int active;
  final int onLeave;
  final int medAdminCertified;

  const StaffSummary({
    this.staff = 0,
    this.active = 0,
    this.onLeave = 0,
    this.medAdminCertified = 0,
  });
}

/// Schedule tab row (`GET /shifts?residenceId=&from=&to=`).
@immutable
class ResidenceShift {
  final String id;
  final String? title;
  final String? shiftType;
  final String? status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int assignedCount;
  final int requiredStaffCount;
  final String? requiredCategoryName;

  const ResidenceShift({
    required this.id,
    this.title,
    this.shiftType,
    this.status,
    this.startsAt,
    this.endsAt,
    this.assignedCount = 0,
    this.requiredStaffCount = 1,
    this.requiredCategoryName,
  });
}

/// Daily Logs tab row (`GET /daily-logs?status=review|missing`).
@immutable
class ResidenceLogDay {
  final String clientName;
  final DateTime? logDate;
  final int entriesCount;

  const ResidenceLogDay({
    required this.clientName,
    this.logDate,
    this.entriesCount = 0,
  });
}
