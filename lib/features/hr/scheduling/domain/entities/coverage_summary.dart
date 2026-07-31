import 'package:flutter/foundation.dart';

import 'scheduling_enums.dart';

/// A single tile in the Board tab's "Today's Coverage" row, e.g.
/// "Morning · 8/10 · Almost Full".
@immutable
class CoverageSummary {
  final String periodLabel;
  final String ratioLabel;
  final CoverageStatus status;
  final String statusLabel;

  const CoverageSummary({
    required this.periodLabel,
    required this.ratioLabel,
    required this.status,
    required this.statusLabel,
  });
}
