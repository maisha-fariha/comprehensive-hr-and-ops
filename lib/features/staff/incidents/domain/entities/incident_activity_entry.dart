import 'package:flutter/foundation.dart';

/// One row in the Incident Details activity log.
@immutable
class IncidentActivityEntry {
  final String title;
  final String meta;
  final bool isActive;

  /// When true, show the web-style FAILURE outcome chip.
  final bool isFailure;

  const IncidentActivityEntry({
    required this.title,
    required this.meta,
    this.isActive = false,
    this.isFailure = false,
  });
}
