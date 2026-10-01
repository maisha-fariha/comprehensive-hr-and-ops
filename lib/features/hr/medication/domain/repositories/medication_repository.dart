import 'package:gems_core/gems_core.dart';

import '../entities/mar_administration.dart';
import '../entities/mar_medication.dart';
import '../entities/mar_options.dart';
import '../entities/mar_round.dart';

/// Everything the web Medication Administration Record page reads and writes.
abstract class MedicationRepository {
  /// `GET /mar/round` — today's doses and the KPI summary.
  Future<Result<MarRound>> round({String? residenceId});

  /// `GET /medications` — every prescription in scope.
  Future<Result<List<MarMedication>>> medications({String? residenceId});

  /// `GET /prn-medications`.
  Future<Result<List<MarMedication>>> prnMedications({String? residenceId});

  /// `GET /mar/administrations` — the Given tab (first 50).
  Future<Result<List<MarAdministration>>> administrations();

  /// `GET /mar/residents/:clientId/chart`.
  Future<Result<MarResidentChart>> residentChart(String clientId);

  Future<Result<List<MarOption>>> residences();
  Future<Result<List<MarClientOption>>> clients();

  /// `GET /staff`, kept to the people approved to give medicine.
  Future<Result<List<MarOption>>> approvedStaff();

  /// `GET /mar/witnesses?residenceId=` — colleagues on duty there.
  Future<Result<List<MarOption>>> witnesses(String residenceId);

  /// `GET /recurring-checks/schedules` (active only).
  Future<Result<List<MarOption>>> checkSchedules({String? clientId});

  Future<Result<void>> createMedication(MarMedicineDraft draft);
  Future<Result<void>> createMedicationBatch(List<MarMedicineDraft> drafts);
  Future<Result<void>> updateMedication(String id, MarMedicineDraft draft);
  Future<Result<void>> discontinueMedication(String id);
  Future<Result<void>> deleteMedication(String id);

  Future<Result<void>> createPrn(MarMedicineDraft draft);
  Future<Result<void>> createPrnBatch(List<MarMedicineDraft> drafts);
  Future<Result<void>> updatePrn(String id, MarMedicineDraft draft);
  Future<Result<void>> discontinuePrn(String id);
  Future<Result<void>> deletePrn(String id);

  /// `POST /mar/administrations/round`.
  Future<Result<void>> chartRound(MarRoundDraft draft);

  /// `POST /uploads?category=documents` then `POST /documents` against the
  /// resident, `management_only`.
  Future<Result<void>> fileEvidence({
    required MarEvidenceFile file,
    required String name,
    required String clientId,
  });

  /// `POST /mar/administrations/:id/amendments`.
  Future<Result<void>> amend(
    String administrationId, {
    required String reason,
    String? status,
    String? doseReason,
  });

  /// Web "Export MAR" (`reportKey: mar_administrations`), CSV bytes.
  Future<Result<List<int>>> exportMarCsv();
}
