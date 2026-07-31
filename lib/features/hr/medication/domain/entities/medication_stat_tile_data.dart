import 'package:flutter/foundation.dart';

import 'medication_enums.dart';

/// A single tile in a stat grid (Overview's 2x2 grid, or the Missed/Refused
/// tabs' 2-tile rows), e.g. "92% Compliance" or "2 Missed Today".
@immutable
class MedicationStatTileData {
  final String id;
  final MedicationStatTag tag;
  final String value;
  final String label;

  const MedicationStatTileData({
    required this.id,
    required this.tag,
    required this.value,
    required this.label,
  });
}
