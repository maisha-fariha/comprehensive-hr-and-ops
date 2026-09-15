import 'package:flutter/foundation.dart';

@immutable
class StaffProfile {
  final String initials;
  final String name;
  final String role;
  final String email;
  final String? residenceName;

  const StaffProfile({
    required this.initials,
    required this.name,
    required this.role,
    required this.email,
    this.residenceName,
  });
}
