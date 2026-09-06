import 'package:flutter/foundation.dart';

/// A selectable client/resident from `GET /clients?search=`.
@immutable
class IncidentClientOption {
  final String id;
  final String name;
  final String? residenceId;
  final String? residenceName;
  final String? subtitle;

  const IncidentClientOption({
    required this.id,
    required this.name,
    this.residenceId,
    this.residenceName,
    this.subtitle,
  });
}
