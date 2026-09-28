import 'package:flutter/foundation.dart';

@immutable
class StaffShiftResidenceOption {
  final String id;
  final String name;

  const StaffShiftResidenceOption({required this.id, required this.name});
}

@immutable
class StaffShiftStaffOption {
  final String id;
  final String name;
  final String detail;
  final String initials;

  const StaffShiftStaffOption({
    required this.id,
    required this.name,
    required this.detail,
    required this.initials,
  });
}
