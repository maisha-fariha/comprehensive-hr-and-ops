import 'package:flutter/foundation.dart';

@immutable
class HrMessageContact {
  final String id;
  final String name;
  final List<String> roles;
  final List<String> residenceIds;

  const HrMessageContact({
    required this.id,
    required this.name,
    this.roles = const [],
    this.residenceIds = const [],
  });

  String get roleLabel => roles.isEmpty ? 'Contact' : roles.first;
}
