import 'package:flutter/foundation.dart';

/// Residence option for Create Task (`GET /residences`).
@immutable
class TaskResidenceOption {
  final String id;
  final String name;

  const TaskResidenceOption({required this.id, required this.name});
}
