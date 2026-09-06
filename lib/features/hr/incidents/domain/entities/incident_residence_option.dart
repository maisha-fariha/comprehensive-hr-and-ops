import 'package:flutter/foundation.dart';

/// A selectable residence from `GET /residences`.
@immutable
class IncidentResidenceOption {
  final String id;
  final String name;

  const IncidentResidenceOption({
    required this.id,
    required this.name,
  });
}
