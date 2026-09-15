import 'package:flutter/foundation.dart';

/// Row from `GET /recurring-checks/instances?from&to&mine=true`.
@immutable
class RecurringCheckInstance {
  final String id;
  final String title;
  final String statusRaw;
  final String dueLabel;
  final String location;

  const RecurringCheckInstance({
    required this.id,
    required this.title,
    this.statusRaw = '',
    this.dueLabel = '',
    this.location = '',
  });

  bool get isOpen {
    final s = statusRaw.toLowerCase();
    return s.isEmpty ||
        s == 'pending' ||
        s == 'due' ||
        s == 'open' ||
        s == 'in_progress';
  }
}
