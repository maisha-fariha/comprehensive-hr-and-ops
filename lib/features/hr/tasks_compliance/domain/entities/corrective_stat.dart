import 'package:flutter/foundation.dart';

import 'tasks_compliance_enums.dart';

/// A single tile in the "Corrective" tab's 2x2 stat grid, e.g.
/// "4 Open Actions".
@immutable
class CorrectiveStat {
  final String id;
  final CorrectiveStatTag tag;
  final String value;
  final String label;

  const CorrectiveStat({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
