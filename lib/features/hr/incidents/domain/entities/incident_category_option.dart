import 'package:flutter/foundation.dart';

/// A selectable incident category from `GET /incident-categories`.
@immutable
class IncidentCategoryOption {
  final String id;
  final String name;

  const IncidentCategoryOption({
    required this.id,
    required this.name,
  });
}
