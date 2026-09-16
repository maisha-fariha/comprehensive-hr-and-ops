import 'package:gems_core/gems_core.dart';

import '../entities/staff_shift_handover.dart';

/// Staff APIs that exist outside the main Figma flows (B10).
abstract class StaffExtrasRepository {
  Future<Result<List<StaffShiftHandover>>> getHandovers({String? residenceId});

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
}
