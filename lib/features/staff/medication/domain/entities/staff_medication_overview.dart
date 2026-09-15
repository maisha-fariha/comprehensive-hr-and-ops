import 'package:flutter/foundation.dart';

import 'administered_dose.dart';
import 'due_dose.dart';
import 'missed_dose.dart';
import 'refused_dose.dart';

/// Aggregate root for the Staff Medication MAR screen.
///
/// Built from a single `GET /mar/round` response: tab lists from
/// `occurrences[]`, header counters from `summary`.
@immutable
class StaffMedicationOverview {
  final String screenTitle;

  final List<DueDose> dueNowDoses;
  final List<DueDose> laterTodayDoses;
  final List<AdministeredDose> administeredDoses;
  final List<MissedDose> missedDoses;
  final List<RefusedDose> refusedDoses;

  /// Counts from round `summary` (fallback to list lengths when absent).
  final int dueCount;
  final int administeredCount;
  final int missedCount;
  final int refusedCount;

  const StaffMedicationOverview({
    required this.screenTitle,
    required this.dueNowDoses,
    required this.laterTodayDoses,
    required this.administeredDoses,
    required this.missedDoses,
    required this.refusedDoses,
    int? dueCount,
    int? administeredCount,
    int? missedCount,
    int? refusedCount,
  })  : dueCount = dueCount ?? (dueNowDoses.length + laterTodayDoses.length),
        administeredCount = administeredCount ?? administeredDoses.length,
        missedCount = missedCount ?? missedDoses.length,
        refusedCount = refusedCount ?? refusedDoses.length;

  StaffMedicationOverview copyWith({
    List<DueDose>? dueNowDoses,
    List<DueDose>? laterTodayDoses,
  }) {
    return StaffMedicationOverview(
      screenTitle: screenTitle,
      dueNowDoses: dueNowDoses ?? this.dueNowDoses,
      laterTodayDoses: laterTodayDoses ?? this.laterTodayDoses,
      administeredDoses: administeredDoses,
      missedDoses: missedDoses,
      refusedDoses: refusedDoses,
      dueCount: dueCount,
      administeredCount: administeredCount,
      missedCount: missedCount,
      refusedCount: refusedCount,
    );
  }
}
