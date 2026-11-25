import 'package:flutter/foundation.dart';

@immutable
class HrMessageContact {
  final String id;
  final String name;
  final List<String> roles;
  final List<String> residenceIds;
  final String? relationship;

  /// Web `tenantWide` — management who belong to every home.
  final bool tenantWide;

  const HrMessageContact({
    required this.id,
    required this.name,
    this.roles = const [],
    this.residenceIds = const [],
    this.relationship,
    this.tenantWide = false,
  });

  /// Web `belongsToHome`: tenant-wide people or those posted to [residenceId].
  bool belongsToHome(String residenceId) =>
      tenantWide || residenceIds.contains(residenceId);

  String get roleLabel {
    final relation = relationship?.trim();
    if (relation != null && relation.isNotEmpty) return relation;
    return roles.isEmpty ? 'Contact' : roles.first;
  }
}
