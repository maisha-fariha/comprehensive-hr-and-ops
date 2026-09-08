import 'package:flutter/foundation.dart';

/// A selectable staff member for Create Shift assignment (`GET /staff`).
@immutable
class ShiftStaffOption {
  final String id;
  final String name;
  final String detail;
  final String initials;
  final String? role;

  const ShiftStaffOption({
    required this.id,
    required this.name,
    required this.detail,
    required this.initials,
    this.role,
  });
}
