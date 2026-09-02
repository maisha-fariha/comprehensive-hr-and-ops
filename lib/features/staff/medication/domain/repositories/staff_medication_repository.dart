import 'package:gems_core/gems_core.dart';

import '../entities/staff_medication_overview.dart';

/// Contract for fetching the Staff "Medication MAR" (Medication
/// Administration Record) summary. The presentation layer only ever
/// depends on this interface, so swapping the mocked
/// [StaffMedicationRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class StaffMedicationRepository {
  Future<Result<StaffMedicationOverview>> getOverview();

  Future<Result<void>> recordAdministration({
    required String clientId,
    required String residenceId,
    required String medicationId,
    required String status,
  });
}
