import 'package:gems_core/gems_core.dart';

import '../../../../hr/medication/domain/entities/mar_medication_stock.dart';
import '../../../../hr/medication/domain/entities/mar_round.dart';
import '../entities/administered_dose.dart';
import '../entities/staff_client_medication_item.dart';
import '../entities/staff_med_options.dart';
import '../entities/staff_medication_overview.dart';

/// Staff Medication MAR — single round fetch fills all four tabs.
abstract class StaffMedicationRepository {
  /// `GET /mar/round` — optional `residenceId` (web registry filter).
  Future<Result<StaffMedicationOverview>> getOverview({String? residenceId});

  /// `POST /mar/administrations/round` — same path as web Record
  /// Administration (status: administered | refused | missed | withheld |
  /// not_available | late).
  Future<Result<void>> recordAdministration({
    required String clientId,
    required String residenceId,
    required String medicationId,
    required String status,
    String? notes,
    String? clinicalNotes,
    String? doseReason,
    String? witnessStaffId,
    bool isPrn = false,
    /// Web `scheduledFor` — occurrence `dueAt` ISO (required to chart a
    /// specific overdue/due slot when the same med has multiple times).
    DateTime? scheduledFor,
    bool scheduled = true,
    Map<String, bool>? safetyChecks,
    Map<String, String>? vitals,
  });

  /// `GET /medications?clientId=`
  Future<Result<List<StaffClientMedicationItem>>> getClientMedications(
    String clientId,
  );

  /// `GET /prn-medications?clientId=`
  Future<Result<List<StaffClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  );

  /// `GET /prn-medications` — optional residence filter (web PRN tab).
  Future<Result<List<StaffClientMedicationItem>>> listPrnMedications({
    String? residenceId,
  });

  /// `GET /mar/administrations` — web Given tab history + badge total.
  Future<Result<MarAdministrationsList>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  });

  /// `GET /medications` — optional filters (resident chart / record admin).
  ///
  /// Pass [type] `scheduled` for the Stock tab.
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
    String? type,
  });

  /// `GET /medication-stock` — web Stock tab.
  Future<Result<List<MarMedicationStock>>> listMedicationStock({
    String? residenceId,
  });

  /// `PUT /medication-stock` — web Count stock.
  Future<Result<MarMedicationStock>> setMedicationStock(
    MarStockCountDraft draft,
  );

  /// `POST /medications`
  Future<Result<void>> createMedication(StaffCreateMedicationInput input);

  /// `PATCH /medications/:id` (web Edit, `mar:write`).
  Future<Result<void>> updateMedication(
    String id,
    StaffCreateMedicationInput input,
  );

  /// `POST /prn-medications`
  Future<Result<void>> createPrnMedication(StaffCreatePrnMedicationInput input);

  /// `PATCH /prn-medications/:id` (web Edit, `mar:write`).
  Future<Result<void>> updatePrnMedication(
    String id,
    StaffCreatePrnMedicationInput input,
  );

  /// `DELETE /medications/:id` (web Delete prescription).
  Future<Result<void>> deleteMedication(String id);

  /// `POST /medications/:id/discontinue`.
  Future<Result<void>> discontinueMedication(String id);

  /// `DELETE /prn-medications/:id`.
  Future<Result<void>> deletePrnMedication(String id);

  /// `POST /prn-medications/:id/discontinue`.
  Future<Result<void>> discontinuePrnMedication(String id);

  /// `GET /mar/residents/:clientId/chart` — web Resident chart tab.
  Future<Result<MarResidentChart>> residentChart(String clientId);

  /// `GET /residences` for Add Medicine house picker.
  Future<Result<List<StaffMedResidenceOption>>> getResidences();

  /// `GET /clients` for Add Medicine resident picker.
  Future<Result<List<StaffMedClientOption>>> getClients({
    String? residenceId,
    String? search,
  });

  /// `GET /recurring-checks/schedules` for "Requires a check first".
  Future<Result<List<StaffMedCheckOption>>> getCheckSchedules({
    String? residenceId,
  });
}
