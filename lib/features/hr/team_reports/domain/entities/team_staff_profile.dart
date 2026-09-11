import 'package:flutter/foundation.dart';

/// Detail payload for `GET /staff/{id}` + `GET /staff/{id}/documents`.
@immutable
class TeamStaffProfile {
  final String id;
  final String name;
  final String initials;
  final String? email;
  final String? phone;
  final String? role;
  final String? residenceName;
  final List<TeamStaffDocument> documents;

  const TeamStaffProfile({
    required this.id,
    required this.name,
    required this.initials,
    this.email,
    this.phone,
    this.role,
    this.residenceName,
    this.documents = const [],
  });
}

@immutable
class TeamStaffDocument {
  final String id;
  final String title;
  final String? updatedLabel;

  const TeamStaffDocument({
    required this.id,
    required this.title,
    this.updatedLabel,
  });
}
