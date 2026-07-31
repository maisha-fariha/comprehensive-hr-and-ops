import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single tile in the "Compliance" tab's 3-column stat row, e.g.
/// "42 Completed".
@immutable
class ComplianceStat {
  final String id;
  final ComplianceStatTag tag;
  final String value;
  final String label;

  const ComplianceStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
