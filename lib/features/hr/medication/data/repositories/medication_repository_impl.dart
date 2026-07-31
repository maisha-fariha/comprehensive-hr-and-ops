import 'package:gems_core/gems_core.dart';

import '../../domain/entities/medication_alert.dart';
import '../../domain/entities/medication_dose.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/entities/medication_stat_tile_data.dart';
import '../../domain/entities/missed_medication.dart';
import '../../domain/entities/refused_medication.dart';
import '../../domain/entities/schedule_dose.dart';
import '../../domain/repositories/medication_repository.dart';

/// Local implementation of [MedicationRepository].
///
/// There is no backend endpoint for the Medication MAR summary yet, so this
/// returns the exact static content shown in the reference screenshots.
/// Replace the body of [getOverview] with a real `ApiService`/
/// `BaseRepository` call once an API contract exists — the domain layer and
/// every widget above it will keep working unchanged.
class MedicationRepositoryImpl implements MedicationRepository {
  @override
  Future<Result<MedicationOverview>> getOverview() async {
    return Result.success(
      const MedicationOverview(
        screenTitle: 'Medication MAR',
        screenSubtitle: 'Oversight · 4 residences',
        dueCount: 5,
        missedCount: 2,
        refusedCount: 1,
        overviewStats: [
          MedicationStatTileData(
            id: 'compliance',
            tag: MedicationStatTag.compliance,
            value: '92%',
            label: 'Compliance',
          ),
          MedicationStatTileData(
            id: 'due-today',
            tag: MedicationStatTag.dueToday,
            value: '5',
            label: 'Due Today',
          ),
          MedicationStatTileData(
            id: 'missed',
            tag: MedicationStatTag.missedCount,
            value: '2',
            label: 'Missed',
          ),
          MedicationStatTileData(
            id: 'refused',
            tag: MedicationStatTag.refusedCount,
            value: '1',
            label: 'Refused',
          ),
        ],
        dueTodayDoses: [
          MedicationDose(
            id: 'due-james-d',
            residentName: 'James D.',
            residentInitials: 'JD',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Lisinopril',
            dose: '10mg',
            timeLabel: '8:00 AM',
          ),
          MedicationDose(
            id: 'due-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Metformin',
            dose: '500mg',
            timeLabel: '12:00 PM',
          ),
          MedicationDose(
            id: 'due-robert-h',
            residentName: 'Robert H.',
            residentInitials: 'RH',
            avatarColor: AvatarPalette.purple,
            medicationName: 'Atorvastatin',
            dose: '20mg',
            timeLabel: '6:00 AM',
          ),
        ],
        moreDueTodayCount: 2,
        missedRefusedAlerts: [
          MedicationAlert(
            id: 'alert-maria-s-refused',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Tylenol 500mg',
            timeLabel: '10:30 AM',
            kind: AlertKind.refused,
            note: 'Resident declined medication',
          ),
        ],
        scheduleTitle: "Today's Medication Schedule",
        scheduleSubtitle: '5 doses scheduled across 4 residences',
        priorityDoses: [
          ScheduleDose(
            id: 'schedule-james-d',
            residentName: 'James D.',
            residentInitials: 'JD',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Lisinopril',
            dose: '10mg',
            scheduledTime: '8:00 AM',
            assigneeName: 'Mike T.',
            assigneeInitials: 'MT',
            assigneeAvatarColor: AvatarPalette.purple,
            status: DoseStatus.dueSoon,
          ),
          ScheduleDose(
            id: 'schedule-sarah-j',
            residentName: 'Sarah J.',
            residentInitials: 'SJ',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Vitamin D',
            dose: '1000 IU',
            scheduledTime: '9:00 AM',
            assigneeName: 'Mike T.',
            assigneeInitials: 'MT',
            assigneeAvatarColor: AvatarPalette.purple,
            status: DoseStatus.dueSoon,
          ),
        ],
        laterTodayDoses: [
          ScheduleDose(
            id: 'schedule-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Metformin',
            dose: '500mg',
            scheduledTime: '12:00 PM',
            assigneeName: 'Diego L.',
            assigneeInitials: 'DL',
            assigneeAvatarColor: AvatarPalette.green,
            status: DoseStatus.upcoming,
          ),
          ScheduleDose(
            id: 'schedule-robert-h',
            residentName: 'Robert H.',
            residentInitials: 'RH',
            avatarColor: AvatarPalette.purple,
            medicationName: 'Atorvastatin',
            dose: '20mg',
            scheduledTime: '6:00 AM',
            assigneeName: 'Sarah J.',
            assigneeInitials: 'SJ',
            assigneeAvatarColor: AvatarPalette.blue,
            status: DoseStatus.completed,
          ),
          ScheduleDose(
            id: 'schedule-james-d-evening',
            residentName: 'James D.',
            residentInitials: 'JD',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Lisinopril',
            dose: '10mg',
            scheduledTime: '8:00 PM',
            assigneeName: 'Mike T.',
            assigneeInitials: 'MT',
            assigneeAvatarColor: AvatarPalette.purple,
            status: DoseStatus.upcoming,
          ),
        ],
        missedStats: [
          MedicationStatTileData(
            id: 'missed-today',
            tag: MedicationStatTag.missedToday,
            value: '2',
            label: 'Missed Today',
          ),
          MedicationStatTileData(
            id: 'critical-missed',
            tag: MedicationStatTag.criticalMissed,
            value: '1',
            label: 'Critical Missed',
          ),
        ],
        missedMedications: [
          MissedMedication(
            id: 'missed-robert-h',
            residentName: 'Robert H.',
            residentInitials: 'RH',
            avatarColor: AvatarPalette.purple,
            medicationName: 'Vitamin D',
            dose: '1000 IU',
            scheduledTime: '8:00 AM',
            missedTimeAgo: '45 min ago',
            assigneeName: 'Sarah J.',
            assigneeInitials: 'SJ',
            assigneeAvatarColor: AvatarPalette.blue,
            isCritical: true,
          ),
          MissedMedication(
            id: 'missed-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Metformin',
            dose: '500mg',
            scheduledTime: '7:30 AM',
            missedTimeAgo: '20 min ago',
            assigneeName: 'Diego L.',
            assigneeInitials: 'DL',
            assigneeAvatarColor: AvatarPalette.green,
          ),
        ],
        refusedStats: [
          MedicationStatTileData(
            id: 'total-refused',
            tag: MedicationStatTag.totalRefused,
            value: '1',
            label: 'Total Refused',
          ),
          MedicationStatTileData(
            id: 'needs-follow-up',
            tag: MedicationStatTag.needsFollowUp,
            value: '1',
            label: 'Needs Follow-up',
          ),
        ],
        refusedMedications: [
          RefusedMedication(
            id: 'refused-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Tylenol',
            dose: '500mg',
            refusedTime: '10:30 AM',
            reason: 'Resident declined medication',
            reportedByName: 'Sarah J.',
            reportedByInitials: 'SJ',
            reportedByAvatarColor: AvatarPalette.blue,
            needsFollowUp: true,
          ),
        ],
      ),
    );
  }
}
