import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/repositories/daily_logs_repository.dart';
import '../mappers/daily_logs_mapper.dart';

/// Loads the Manager Daily Logs screen from Manager A4 Postman contracts:
/// - `GET /daily-logs?status=review&residenceId&from&to`
/// - `GET /daily-logs?status=missing&residenceId&from&to`
/// - `GET /care-flags?state=open&page&limit&residenceId`
/// - `GET /shift-handovers?page&limit&residenceId&status=submitted`
///
/// Falls back to `GET /daily-logs/entries` only when the primary daily-logs
/// path rejects the query (also present in Manager A4).
class DailyLogsRepositoryImpl implements DailyLogsRepository {
  static const _pageSize = 100;
  static const _rangeDays = 14;

  final AppApiClient _api;
  final UserSession _session;

  DailyLogsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<DailyLogsOverview>> getOverview() async {
    final residenceId = _session.residenceId;
    final range = <String, dynamic>{
      'from': IsoDateRange.daysAgoStartIso(_rangeDays),
      'to': IsoDateRange.todayEndIso,
      'residenceId': ?residenceId,
    };

    // Silent GETs — controller shows a single error/empty state.
    final results = await Future.wait([
      _fetchDailyLogs({...range, 'status': 'review'}, silent: true),
      _fetchDailyLogs({...range, 'status': 'missing'}, silent: true),
      _api.get(
        ApiEndpoints.careFlags,
        query: {
          'state': 'open',
          'page': 1,
          'limit': _pageSize,
          'residenceId': ?residenceId,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.shiftHandovers,
        query: {
          'page': 1,
          'limit': _pageSize,
          'status': 'submitted',
          'residenceId': ?residenceId,
        },
        silent: true,
      ),
    ]);

    final review = results[0];
    final missing = results[1];
    final flags = results[2];
    final handovers = results[3];

    final reviewOk = review.isSuccess;
    final missingOk = missing.isSuccess;
    final handoversOk = handovers.isSuccess;

    if (!reviewOk && !missingOk && !handoversOk) {
      return Result.failure(
        review.error ??
            missing.error ??
            handovers.error ??
            const ApiError(message: 'Could not load daily logs.'),
      );
    }

    return Result.success(
      DailyLogsMapper.compose(
        reviewBody: reviewOk ? review.value : null,
        flagsBody: flags.isSuccess ? flags.value : null,
        missingBody: missingOk ? missing.value : null,
        handoversBody: handoversOk ? handovers.value : null,
        residenceName: _session.residenceName,
      ),
    );
  }

  Future<Result<dynamic>> _fetchDailyLogs(
    Map<String, dynamic> query, {
    bool silent = false,
  }) async {
    final primary = await _api.get(
      ApiEndpoints.dailyLogs,
      query: query,
      silent: silent,
    );
    if (primary.isSuccess) return primary;

    final error = primary.error;
    final shouldFallback = error is ApiError || error is ValidationError;
    if (!shouldFallback) return primary;

    return _api.get(
      ApiEndpoints.dailyLogEntries,
      query: query,
      silent: true,
    );
  }

  @override
  Future<Result<void>> acknowledgeHandover(String handoverId) async {
    final trimmed = handoverId.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const ApiError(message: 'Missing handover id.'),
      );
    }

    final result = await _api.post(
      ApiEndpoints.handoverAcknowledge(trimmed),
      data: const <String, dynamic>{},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
