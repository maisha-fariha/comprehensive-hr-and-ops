import 'package:gems_core/gems_core.dart';

import '../entities/staff_residence.dart';
import '../entities/staff_shift_handover.dart';

/// Staff APIs that exist outside the main Figma flows (B10).
abstract class StaffExtrasRepository {
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
    String? authorId,
  });

  Future<Result<StaffShiftHandover>> getHandoverDetail(String handoverId);

  Future<Result<String>> createHandover({
    required String residenceId,
    required String summary,
    bool submit,
    String? fromShiftId,
    String? toShiftId,
    List<Map<String, dynamic>> pendingActions,
    List<Map<String, dynamic>> clientUpdates,
    Map<String, dynamic>? flagForAttention,
  });

  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  });

  Future<Result<void>> deleteHandover(String handoverId);

  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  });

  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  });

  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page,
    int limit,
  });

  Future<Result<List<Map<String, String>>>> getReferrals();

  Future<Result<Map<String, dynamic>>> getCourseQuiz(String courseId);

  Future<Result<Map<String, dynamic>>> submitQuizAttempt({
    required String courseId,
    required List<Map<String, dynamic>> answers,
  });

  Future<Result<List<Map<String, String>>>> getTrainingCertificates();

  /// `GET /residences` — residences available to the signed-in staff member.
  Future<Result<List<StaffResidence>>> getResidences();

  /// `GET /residences/:id` — full residence detail (matches web Residences view).
  Future<Result<StaffResidence>> getResidenceDetail(String residenceId);

  /// Active residents living today — `GET /clients?status=active` (web KPI).
  Future<Result<int>> getActiveResidentCount();

  /// `PATCH /residences/:id` — update residence fields (web Edit action).
  Future<Result<StaffResidence>> updateResidence({
    required String residenceId,
    required Map<String, dynamic> fields,
  });

  /// Soft-deactivate / archive residence (web circle-slash action).
  Future<Result<StaffResidence>> deactivateResidence(String residenceId);

  /// Nested View tabs — clients at this residence.
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  );

  /// Nested View tabs — rooms at this residence.
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  );

  /// Nested View tabs — staff posted at this residence.
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  );

  /// Nested View tabs — upcoming / recent shifts.
  Future<Result<List<Map<String, String>>>> getResidenceShifts(
    String residenceId,
  );

  /// Nested View tabs — daily logs (missing + review).
  Future<Result<List<Map<String, String>>>> getResidenceDailyLogs(
    String residenceId,
  );

  /// Staff directory options for manager / assigned staff pickers.
  Future<Result<List<StaffResidencePerson>>> getStaffDirectoryOptions();
}
