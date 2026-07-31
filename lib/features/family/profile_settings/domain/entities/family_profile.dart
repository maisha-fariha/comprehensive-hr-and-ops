import 'package:flutter/foundation.dart';

/// The signed-in family member's own profile, shown in the top card of the
/// "Profile & Settings" screen.
@immutable
class FamilyProfile {
  final String initials;
  final String name;
  final String relationship;
  final String email;

  const FamilyProfile({
    required this.initials,
    required this.name,
    required this.relationship,
    required this.email,
  });
}
