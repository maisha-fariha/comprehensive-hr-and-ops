import 'package:flutter/foundation.dart';

/// Lightweight staff row for Team Overview / profile open.
@immutable
class TeamStaffMember {
  final String id;
  final String name;
  final String initials;
  final String? role;

  const TeamStaffMember({
    required this.id,
    required this.name,
    required this.initials,
    this.role,
  });
}
