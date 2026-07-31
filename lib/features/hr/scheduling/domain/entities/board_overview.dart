import 'package:flutter/foundation.dart';

import 'board_shift.dart';
import 'coverage_summary.dart';
import 'open_position.dart';

/// Aggregate for everything shown on the Board tab.
@immutable
class BoardOverview {
  final List<CoverageSummary> coverageSummaries;
  final List<BoardShift> shifts;
  final List<OpenPosition> openPositions;

  const BoardOverview({
    required this.coverageSummaries,
    required this.shifts,
    required this.openPositions,
  });
}
