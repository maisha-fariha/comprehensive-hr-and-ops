import 'package:flutter/foundation.dart';

import 'dashboard_enums.dart';

/// A single tile in the "Today's Overview" 2-column stat grid, e.g.
/// "12 Staff On Duty" or "3 Open Incidents".
@immutable
class OverviewStat {
  final String id;
  final StatTag tag;
  final String value;
  final String label;
  final String helperText;
  final bool isHelperTextPositive;

  const OverviewStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
    required this.helperText,
    this.isHelperTextPositive = false,
  });
}
