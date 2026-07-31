import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/scheduling_enums.dart';

/// Color grouping for a [CoverageStatus], reused everywhere a shift's
/// staffing health is shown: the Calendar tab's shift cards, the Board
/// tab's "Today's Coverage" tiles and its "Coverage Board" cards.
class CoverageStatusStyle {
  final Color accent;
  final Color background;

  const CoverageStatusStyle({required this.accent, required this.background});
}

const Map<CoverageStatus, CoverageStatusStyle> coverageStatusStyles = {
  CoverageStatus.almostFull: CoverageStatusStyle(
    accent: AppColors.urgentAmber,
    background: AppColors.urgentBackground,
  ),
  CoverageStatus.needsAttention: CoverageStatusStyle(
    accent: AppColors.criticalRed,
    background: AppColors.criticalBackground,
  ),
};
