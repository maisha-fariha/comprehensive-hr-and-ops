import 'package:gems_core/gems_core.dart';

import '../entities/daily_log.dart';

/// Web `/dashboard/daily-logs` reads and writes. Dates are `YYYY-MM-DD`.
abstract class DailyLogsRepository {
  Future<Result<List<DailyLogOption>>> residences();

  Future<Result<List<DailyLogOption>>> clients(String? residenceId);

  /// `GET /staff` — the logbook "All staff" filter.
  Future<Result<List<DailyLogOption>>> staff();

  /// Web Today hub: `GET /daily-logs/board?residenceId&date`.
  Future<Result<DailyLogBoard>> board({
    required String residenceId,
    required String date,
  });

  /// Web resident day feed: `GET /clients/:id/daily-activity-feed?date=`.
  Future<Result<DailyActivityFeed>> activityFeed({
    required String clientId,
    required String date,
  });

  Future<Result<DailyLogPage<DailyLogReviewRow>>> reviewQueue({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  });

  Future<Result<DailyLogPage<DailyLogMissingRow>>> missing({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  });

  /// Null when nothing was written for the resident that day.
  Future<Result<DailyLogDay?>> day({
    required String clientId,
    required String residenceId,
    required String logDate,
  });

  Future<Result<DailyLogEntry>> entry(String id);

  Future<Result<List<DailyLogShiftRow>>> shiftLogs({
    required String residenceId,
    required String logDate,
  });

  /// `{summary?, status?}` with status `completed` or `locked`.
  Future<Result<void>> updateShiftLog(String id, Map<String, dynamic> body);

  Future<Result<void>> createEntry(Map<String, dynamic> body);

  Future<Result<void>> amendEntry(String id, {required String body, required String reason});

  Future<Result<void>> deleteEntry(String id);

  /// Omit [residenceId] for every residence, and [staffId] for every staff
  /// member. The web logbook does both.
  Future<Result<DailyLogPage<ResidenceActivityRow>>> activity({
    String? residenceId,
    String? staffId,
    required String from,
    required String to,
    required int page,
    required int limit,
  });

  /// Open flags (first 20) and the open total.
  Future<Result<DailyLogPage<CareFlag>>> openFlags(String? residenceId);

  Future<Result<void>> resolveFlag(String id, {String? note});

  /// `POST /uploads?category=daily-log-attachment`.
  Future<Result<DailyLogUpload>> upload(String path, String fileName);

  /// Web day card: `GET /daily-summaries/clients/:id?from&to&limit=1`.
  Future<Result<DailySummary?>> daySummary({
    required String clientId,
    required String day,
  });

  /// `POST /daily-summaries/clients/:id/generate` with `{ day }`.
  Future<Result<DailySummary?>> generateDaySummary({
    required String clientId,
    required String day,
  });

  Future<Result<DailySummary>> updateDaySummary(
    String id, {
    required String summary,
    String? familySummary,
  });

  Future<Result<DailySummary>> shareDaySummary(String id);

  Future<Result<DailySummary>> unshareDaySummary(String id);
}
