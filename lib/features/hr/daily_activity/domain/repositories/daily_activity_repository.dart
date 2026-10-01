import 'package:gems_core/gems_core.dart';

import '../entities/daily_activity.dart';

abstract class DailyActivityRepository {
  /// `GET /client-activities`; dates are `YYYY-MM-DD`.
  Future<Result<DailyActivityListResult>> list({
    required int page,
    required int limit,
    String? search,
    String? clientId,
    String? recordedByStaffId,
    String? activityType,
    String? status,
    String? from,
    String? to,
  });

  /// `GET /client-activities/summary?clientId&month=YYYY-MM`.
  Future<Result<DailyActivityMonthSummary>> monthSummary({
    required String clientId,
    required String month,
  });

  Future<Result<void>> create(DailyActivityDraft draft);

  /// `PATCH /client-activities/:id` with the full form body.
  Future<Result<void>> update(String id, DailyActivityDraft draft);

  /// `PATCH /client-activities/:id` with `{status: reviewed}`.
  Future<Result<void>> markReviewed(String id);

  Future<Result<void>> delete(String id);

  Future<Result<List<DailyActivityOption>>> clients();

  Future<Result<List<DailyActivityOption>>> staff();

  /// `POST /uploads?category=client-activities`; returns the stored file URL.
  Future<Result<String>> upload(DailyActivityLocalFile file);

  Future<Result<List<int>>> download(String fileUrl);
}
