import 'package:flutter/foundation.dart';

/// Staff option for Create Incident people / supervisor pickers
/// (`GET /staff`).
@immutable
class IncidentStaffOption {
  final String id;
  final String name;
  final String? email;
  final String? roleLabel;

  const IncidentStaffOption({
    required this.id,
    required this.name,
    this.email,
    this.roleLabel,
  });

  String? get subtitle {
    final role = roleLabel?.trim();
    if (role == null || role.isEmpty) return 'Staff';
    return role;
  }
}
