import 'package:flutter/foundation.dart';

import 'staff_dashboard_enums.dart';

/// A single tile in the Staff Dashboard's "Today's Overview" 2-column grid,
/// e.g. "On Shift / My Shift" or "8 / Clients Assigned".
@immutable
class StaffOverviewStat {
  final String id;
  final StaffStatTag tag;
  final String value;
  final String label;

  const StaffOverviewStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
