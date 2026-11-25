import 'package:flutter/foundation.dart';

@immutable
class HrMessageContact {
  final String id;
  final String name;
  final List<String> roles;
  final List<String> residenceIds;
  final String? relationship;

  const HrMessageContact({
    required this.id,
    required this.name,
    this.roles = const [],
    this.residenceIds = const [],
    this.relationship,
  });

  String get roleLabel {
    final relation = relationship?.trim();
    if (relation != null && relation.isNotEmpty) return relation;
    return roles.isEmpty ? 'Contact' : roles.first;
  }
}
