import 'package:gems_core/gems_core.dart';

import '../entities/residence_detail_tabs.dart';
import '../entities/residence_form.dart';
import '../entities/residence_summary.dart';

abstract class ResidencesRepository {
  /// Every residence the manager is scoped to (`GET /residences`, all pages).
  Future<Result<List<ResidenceSummary>>> getResidences();

  /// Room board for one home (`GET /residences/{id}/rooms`).
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId);
}

/// Everything the web "Residences Management" page, its Actions menu, the
/// Add/Edit wizard and the residence detail drawer call.
abstract class ResidenceAdminRepository {
  /// `GET /residences?page&limit&search&status&residenceType`.
  Future<Result<ResidencesPageData>> listResidences({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? residenceType,
  });

  Future<Result<ResidenceSummary>> getResidence(String residenceId);

  /// `POST /residences`, then `PUT /residences/{id}/assignments` when any.
  Future<Result<ResidenceSummary>> createResidence(
    Map<String, dynamic> body,
    List<ResidenceAssignment> assignments,
  );

  /// `PATCH /residences/{id}`, then `PUT .../assignments` when given.
  Future<Result<ResidenceSummary>> updateResidence(
    String residenceId,
    Map<String, dynamic> body, {
    List<ResidenceAssignment>? assignments,
  });

  /// `PATCH /residences/{id}/status`.
  Future<Result<void>> setStatus(String residenceId, String status);

  /// `DELETE /residences/{id}` (soft delete on the server).
  Future<Result<void>> deleteResidence(String residenceId);

  /// `PATCH /residences/{id}/payroll-settings`.
  Future<Result<void>> updatePayrollSettings(
    String residenceId, {
    required bool outOfPocketEnabled,
    required bool mileageEnabled,
  });

  Future<Result<ResidenceRoomBoard>> getRoomBoard(
    String residenceId, {
    bool includeArchived = false,
  });

  /// `POST /residences/{id}/rooms`.
  Future<Result<void>> createRoom(
    String residenceId, {
    required String name,
    required int capacity,
    String? floor,
    String? wing,
    String? roomType,
  });

  /// `PATCH /residences/{id}/rooms/{roomId}` with `{ isActive: true }`.
  Future<Result<void>> reactivateRoom(String residenceId, String roomId);

  /// `DELETE /residences/{id}/rooms/{roomId}` (takes the room out of use).
  Future<Result<void>> archiveRoom(String residenceId, String roomId);

  Future<Result<ResidenceTabPage<ResidenceResident, ResidentsSummary>>>
      getResidents(String residenceId, {required int page, required int limit});

  Future<Result<ResidenceTabPage<ResidenceStaffMember, StaffSummary>>>
      getStaff(String residenceId, {required int page, required int limit});

  Future<Result<List<ResidenceShift>>> getShifts(
    String residenceId, {
    required DateTime from,
    required DateTime to,
  });

  /// `GET /daily-logs?status=review`.
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getReviewQueue(
    String residenceId, {
    required int page,
    required int limit,
  });

  /// `GET /daily-logs?status=missing`.
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getMissingLogs(
    String residenceId, {
    required int page,
    required int limit,
  });

  /// Wizard staff pickers (`GET /staff`).
  Future<Result<List<ResidenceStaffOption>>> getStaffOptions();

  /// Plan limit and enabled residence types (`GET /auth/me`).
  Future<Result<ResidenceTenantContext>> getTenantContext();

  /// "Export List": `residence_roster` CSV bytes.
  Future<Result<List<int>>> exportRoster();
}
