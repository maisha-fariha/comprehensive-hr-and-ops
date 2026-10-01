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

  /// Every occurrence of the round in API order, whatever its state: the web
  /// MAR registry rows (given and unscheduled doses included).
  final List<DueDose> registryDoses;

  /// Counts from round `summary` (fallback to list lengths when absent).
  final int dueCount;
  final int administeredCount;
  final int missedCount;
  final int refusedCount;

  /// Web MAR metric strip fields from `summary`.
  final int scheduledCount;
  final int overdueCount;
  final int unscheduledCount;
  final double? complianceRate;

  const StaffMedicationOverview({
    required this.screenTitle,
    required this.dueNowDoses,
    required this.laterTodayDoses,
    required this.administeredDoses,
    required this.missedDoses,
    required this.refusedDoses,
    this.registryDoses = const [],
    int? dueCount,
    int? administeredCount,
    int? missedCount,
    int? refusedCount,
    int? scheduledCount,
    int? overdueCount,
    int? unscheduledCount,
    this.complianceRate,
  })  : dueCount = dueCount ?? (dueNowDoses.length + laterTodayDoses.length),
        administeredCount = administeredCount ?? administeredDoses.length,
        missedCount = missedCount ?? missedDoses.length,
        refusedCount = refusedCount ?? refusedDoses.length,
        scheduledCount = scheduledCount ??
            (dueCount ?? (dueNowDoses.length + laterTodayDoses.length)),
        overdueCount = overdueCount ?? 0,
        unscheduledCount = unscheduledCount ?? 0;

  /// Missed + overdue for the metric strip / side cards.
  int get missedOrOverdueCount => missedCount + overdueCount;

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
      registryDoses: registryDoses,
      dueCount: dueCount,
      administeredCount: administeredCount,
      missedCount: missedCount,
      refusedCount: refusedCount,
      scheduledCount: scheduledCount,
      overdueCount: overdueCount,
      unscheduledCount: unscheduledCount,
      complianceRate: complianceRate,
    );
  }
}
