import 'package:flutter/foundation.dart';

/// Counts from `GET /incidents/summary` for the Staff Incidents header/tab
/// badge.
@immutable
class StaffIncidentsSummary {
  final int total;
  final int open;
  final int investigating;
  final int closed;

  const StaffIncidentsSummary({
    this.total = 0,
    this.open = 0,
    this.investigating = 0,
    this.closed = 0,
  });

  static const empty = StaffIncidentsSummary();
}
