import 'package:flutter/foundation.dart';

@immutable
class HrProfile {
  final String initials;
  final String name;
  final String role;
  final String email;

  const HrProfile({
    required this.initials,
    required this.name,
    required this.role,
    required this.email,
  });
}
