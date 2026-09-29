import 'package:gems_core/gems_core.dart';

import '../entities/daily_log.dart';

/// Web `/dashboard/daily-logs` reads and writes. Dates are `YYYY-MM-DD`.
abstract class DailyLogsRepository {
  Future<Result<List<DailyLogOption>>> residences();

  Future<Result<List<DailyLogOption>>> clients(String? residenceId);

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

  Future<Result<DailyLogPage<ResidenceActivityRow>>> activity({
    required String residenceId,
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
}
