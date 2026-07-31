import 'package:flutter/foundation.dart';

import 'medication_alert.dart';
import 'medication_dose.dart';
import 'medication_stat_tile_data.dart';
import 'missed_medication.dart';
import 'refused_medication.dart';
import 'schedule_dose.dart';

/// Aggregate root for everything shown on the "Medication MAR" screen —
/// the shared header/tab-bar counts plus the per-tab content for all 4
/// tabs (Overview, Due, Missed, Refused).
@immutable
class MedicationOverview {
  final String screenTitle;
  final String screenSubtitle;
  final int dueCount;
  final int missedCount;
  final int refusedCount;

  // Overview tab
  final List<MedicationStatTileData> overviewStats;
  final List<MedicationDose> dueTodayDoses;
  final int moreDueTodayCount;
  final List<MedicationAlert> missedRefusedAlerts;

  // Due tab
  final String scheduleTitle;
  final String scheduleSubtitle;
  final List<ScheduleDose> priorityDoses;
  final List<ScheduleDose> laterTodayDoses;

  // Missed tab
  final List<MedicationStatTileData> missedStats;
  final List<MissedMedication> missedMedications;

  // Refused tab
  final List<MedicationStatTileData> refusedStats;
  final List<RefusedMedication> refusedMedications;

  const MedicationOverview({
    required this.screenTitle,
    required this.screenSubtitle,
    required this.dueCount,
    required this.missedCount,
    required this.refusedCount,
    required this.overviewStats,
    required this.dueTodayDoses,
    required this.moreDueTodayCount,
    required this.missedRefusedAlerts,
    required this.scheduleTitle,
    required this.scheduleSubtitle,
    required this.priorityDoses,
    required this.laterTodayDoses,
    required this.missedStats,
    required this.missedMedications,
    required this.refusedStats,
    required this.refusedMedications,
  });
}
