import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/repositories/daily_logs_repository.dart';
import '../mappers/daily_logs_mapper.dart';

/// Loads the Manager Daily Logs screen from:
/// - `GET /daily-logs` (with `/daily-logs/entries` fallback)
/// - `GET /care-flags?state=open`
/// - `GET /shift-handovers`
class DailyLogsRepositoryImpl implements DailyLogsRepository {
  static const _pageSize = 100;

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
    final base = <String, dynamic>{
      'logDate': IsoDateRange.todayDate,
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'page': 1,
      'limit': _pageSize,
      'residenceId': ?residenceId,
    };

    // All GETs are silent — the controller surfaces a single error dialog /
    // page state so offline or bad status filters do not stack alerts.
    final results = await Future.wait([
      _fetchDailyLogs(
        {
          ...base,
          // Review tab: submitted / awaiting manager review.
          'status': 'submitted,review,in_review,pending,needs_review',
        },
        silent: true,
      ),
      _fetchDailyLogs(
        {...base, 'status': 'missing'},
        silent: true,
      ),
      _fetchDailyLogs(
        {...base, 'status': 'overdue'},
        silent: true,
      ),
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
        query: base,
        silent: true,
      ),
    ]);

    var review = results[0];
    final missing = results[1];
    final overdue = results[2];
    final flags = results[3];
    final handovers = results[4];

    // If status-filtered review fails (unknown enum / 4xx), retry today's logs
    // without a status filter so the Review tab still has data when online.
    if (review.isFailure) {
      review = await _fetchDailyLogs(base, silent: true);
    }

    final reviewOk = review.isSuccess;
    final missingOk = missing.isSuccess || overdue.isSuccess;
    final handoversOk = handovers.isSuccess;

    if (!reviewOk && !missingOk && !handoversOk) {
      return Result.failure(
        review.error ??
            missing.error ??
            overdue.error ??
            handovers.error ??
            const ApiError(message: 'Could not load daily logs.'),
      );
    }

    final missingBody = _mergeListBodies(
      missing.isSuccess ? missing.value : null,
      overdue.isSuccess ? overdue.value : null,
    );

    return Result.success(
      DailyLogsMapper.compose(
        reviewBody: reviewOk ? review.value : null,
        flagsBody: flags.isSuccess ? flags.value : null,
        missingBody: missingBody,
        handoversBody: handoversOk ? handovers.value : null,
      ),
    );
  }

  /// Prefer `GET /daily-logs`; fall back to `GET /daily-logs/entries` when the
  /// collection path rejects the query (common BE split between summary and
  /// entry resources).
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

    // Only fall back on API/validation style failures — not offline, so we
    // do not double-hit the network when the device cannot reach the host.
    final error = primary.error;
    final shouldFallback = error is ApiError || error is ValidationError;
    if (!shouldFallback) return primary;

    return _api.get(
      ApiEndpoints.dailyLogEntries,
      query: query,
      silent: true,
    );
  }

  /// Concatenate two list envelopes into one `{ data: [...] }` payload the
  /// mapper can unwrap, de-duplicating by `id` when present.
  dynamic _mergeListBodies(dynamic first, dynamic second) {
    final a = JsonCodec.unwrapList(first);
    final b = JsonCodec.unwrapList(second);
    if (a.isEmpty && b.isEmpty) return first ?? second;
    if (b.isEmpty) return first;
    if (a.isEmpty) return second;

    final seen = <String>{};
    final merged = <dynamic>[];
    for (final item in [...a, ...b]) {
      if (item is Map) {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) {
          if (seen.contains(id)) continue;
          seen.add(id);
        }
      }
      merged.add(item);
    }
    return {'data': merged};
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
