import 'package:flutter/foundation.dart';

import 'incidents_enums.dart';

/// A single stat tile shown at the top of an Incidents tab, e.g.
/// "4 Open Incidents" or "148 Archived".
@immutable
class IncidentStat {
  final String id;
  final IncidentStatTag tag;
  final String value;
  final String label;

  const IncidentStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
