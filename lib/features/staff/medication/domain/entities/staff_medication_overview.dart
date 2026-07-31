import 'package:flutter/foundation.dart';

import 'administered_dose.dart';
import 'due_dose.dart';
import 'missed_dose.dart';
import 'refused_dose.dart';

/// Aggregate root for everything shown on the Staff "Medication MAR"
/// screen — the shared header plus the per-tab content for all 4 tabs
/// (Due, Administered, Missed, Refused).
@immutable
class StaffMedicationOverview {
  final String screenTitle;

  // Due tab
  final List<DueDose> dueNowDoses;
  final List<DueDose> laterTodayDoses;

  // Administered tab
  final List<AdministeredDose> administeredDoses;

  // Missed tab
  final List<MissedDose> missedDoses;

  // Refused tab
  final List<RefusedDose> refusedDoses;

  const StaffMedicationOverview({
    required this.screenTitle,
    required this.dueNowDoses,
    required this.laterTodayDoses,
    required this.administeredDoses,
    required this.missedDoses,
    required this.refusedDoses,
  });

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
    );
  }
}
