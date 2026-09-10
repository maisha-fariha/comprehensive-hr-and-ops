import 'package:flutter/foundation.dart';

/// A selectable resident from `GET /clients?search=`.
@immutable
class TaskClientOption {
  final String id;
  final String name;
  final String? residenceId;
  final String? subtitle;

  const TaskClientOption({
    required this.id,
    required this.name,
    this.residenceId,
    this.subtitle,
  });
}
