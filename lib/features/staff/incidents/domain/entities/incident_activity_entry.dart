import 'package:flutter/foundation.dart';

/// One row in the Incident Details activity log.
@immutable
class IncidentActivityEntry {
  final String title;
  final String meta;
  final bool isActive;

  const IncidentActivityEntry({
    required this.title,
    required this.meta,
    this.isActive = false,
  });
}
