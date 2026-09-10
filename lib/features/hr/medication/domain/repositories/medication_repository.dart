import 'package:gems_core/gems_core.dart';

import '../entities/client_medication_item.dart';
import '../entities/medication_overview.dart';

/// Contract for fetching the Medication MAR (Medication Administration
/// Record) summary and Missed/Refused follow-up actions.
abstract class MedicationRepository {
  Future<Result<MedicationOverview>> getOverview();

  /// Regular medications for a client (`GET /medications?clientId=`).
  Future<Result<List<ClientMedicationItem>>> getClientMedications(
    String clientId,
  );

  /// PRN medications for a client (`GET /prn-medications?clientId=`).
  Future<Result<List<ClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  );

  /// Review a missed/refused administration
  /// (`POST /compliance/findings` with `sourceType: mar_administration`).
  Future<Result<void>> reviewMedicationIssue({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
    String severity = 'medium',
  });

  /// Log follow-up for a refused (or missed) administration
  /// (`POST /compliance/corrective-actions`, fallback `POST /tasks`).
  Future<Result<void>> logMedicationFollowUp({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
  });
}
