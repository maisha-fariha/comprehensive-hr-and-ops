import 'package:gems_core/gems_core.dart';

import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/due_dose.dart';
import '../../domain/entities/missed_dose.dart';
import '../../domain/entities/refused_dose.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';

/// Local implementation of [StaffMedicationRepository].
///
/// There is no backend endpoint for the Staff Medication MAR summary yet,
/// so this returns the exact static content shown in the reference
/// screenshots. Replace the body of [getOverview] with a real
/// `ApiService`/`BaseRepository` call once an API contract exists — the
/// domain layer and every widget above it will keep working unchanged.
class StaffMedicationRepositoryImpl implements StaffMedicationRepository {
  @override
  Future<Result<StaffMedicationOverview>> getOverview() async {
    return Result.success(
      const StaffMedicationOverview(
        screenTitle: 'Medication MAR',
        dueNowDoses: [
          DueDose(
            id: 'due-james-d',
            residentName: 'James D.',
            residentInitials: 'JD',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Lisinopril',
            dose: '10mg',
            route: MedicationRoute.tabletOral,
            timeLabel: '9:00 AM',
            section: DueDoseSection.dueNow,
          ),
          DueDose(
            id: 'due-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Metformin',
            dose: '500mg',
            route: MedicationRoute.tabletOral,
            timeLabel: '9:00 AM',
            section: DueDoseSection.dueNow,
          ),
        ],
        laterTodayDoses: [
          DueDose(
            id: 'due-robert-h',
            residentName: 'Robert H.',
            residentInitials: 'RH',
            avatarColor: AvatarPalette.amber,
            medicationName: 'Acetaminophen',
            dose: '500mg',
            route: MedicationRoute.tabletOral,
            timeLabel: '11:00 AM',
            section: DueDoseSection.laterToday,
          ),
          DueDose(
            id: 'due-ellen-t',
            residentName: 'Ellen T.',
            residentInitials: 'ET',
            avatarColor: AvatarPalette.purple,
            medicationName: 'Insulin Glargine',
            dose: '12u',
            route: MedicationRoute.injectionSubcut,
            timeLabel: '1:00 PM',
            section: DueDoseSection.laterToday,
            status: DueDoseStatus.upcoming,
          ),
        ],
        administeredDoses: [
          AdministeredDose(
            id: 'admin-james-d',
            residentName: 'James D.',
            residentInitials: 'JD',
            avatarColor: AvatarPalette.blue,
            medicationName: 'Amlodipine',
            dose: '5mg',
            route: MedicationRoute.tabletOral,
            givenTimeLabel: '8:02 AM',
            administeredByName: 'Dana L.',
          ),
          AdministeredDose(
            id: 'admin-maria-s',
            residentName: 'Maria S.',
            residentInitials: 'MS',
            avatarColor: AvatarPalette.green,
            medicationName: 'Levothyroxine',
            dose: '50mcg',
            route: MedicationRoute.tabletOral,
            givenTimeLabel: '7:45 AM',
            administeredByName: 'Dana L.',
          ),
          AdministeredDose(
            id: 'admin-robert-h',
            residentName: 'Robert H.',
            residentInitials: 'RH',
            avatarColor: AvatarPalette.amber,
            medicationName: 'Vitamin D3',
            dose: '1000 IU',
            route: MedicationRoute.capsuleOral,
            givenTimeLabel: '8:15 AM',
            administeredByName: 'Dana L.',
          ),
          AdministeredDose(
            id: 'admin-ellen-t',
            residentName: 'Ellen T.',
            residentInitials: 'ET',
            avatarColor: AvatarPalette.purple,
            medicationName: 'Insulin Glargine',
            dose: '12u',
            route: MedicationRoute.injectionSubcut,
            givenTimeLabel: '7:30 AM',
            administeredByName: 'Priya K.',
          ),
        ],
        missedDoses: [
          MissedDose(
            id: 'missed-george-k',
            residentName: 'George K.',
            residentInitials: 'GK',
            avatarColor: AvatarPalette.green,
            medicationName: 'Warfarin',
            dose: '2mg',
            route: MedicationRoute.tabletOral,
            scheduledTimeLabel: '7:00 AM',
            missedByName: 'Dana L.',
            reason: 'Client at off-site appointment during scheduled window.',
          ),
        ],
        refusedDoses: [
          RefusedDose(
            id: 'refused-laura-a',
            residentName: 'Laura A.',
            residentInitials: 'LA',
            avatarColor: AvatarPalette.red,
            medicationName: 'Metformin',
            dose: '500mg',
            route: MedicationRoute.tabletOral,
            timeLabel: '9:10 AM',
            refusedByName: 'Priya K.',
            notes: 'Client declined, reported nausea. Prescriber notified for review.',
          ),
        ],
      ),
    );
  }
}
