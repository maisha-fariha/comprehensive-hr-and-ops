import 'package:gems_core/gems_core.dart';

import '../entities/staff_client_medication_item.dart';
import '../entities/staff_medication_overview.dart';

/// Staff Medication MAR — single round fetch fills all four tabs.
abstract class StaffMedicationRepository {
  /// `GET /mar/round?residenceId=&date=YYYY-MM-DD`
  Future<Result<StaffMedicationOverview>> getOverview();

  /// `POST /mar/administrations` — status: administered | refused | missed | late.
  Future<Result<void>> recordAdministration({
    required String clientId,
    required String residenceId,
    required String medicationId,
    required String status,
    String? notes,
    bool isPrn = false,
  });

  /// `GET /medications?clientId=`
  Future<Result<List<StaffClientMedicationItem>>> getClientMedications(
    String clientId,
  );

  /// `GET /prn-medications?clientId=`
  Future<Result<List<StaffClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  );
}
