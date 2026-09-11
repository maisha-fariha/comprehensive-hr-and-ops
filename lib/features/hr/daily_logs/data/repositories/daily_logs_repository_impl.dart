import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
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
/// `residenceId` is required by the API whenever `status` is set. If the
/// session has no residence yet, we resolve one from `GET /residences`.
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
    final residenceId = await _resolveResidenceId();
    if (residenceId == null || residenceId.isEmpty) {
      return Result.failure(
        const ValidationError(
          message:
              'Select a residence before opening Daily Logs. The server requires residenceId for review and missing queues.',
        ),
      );
    }

    final range = <String, dynamic>{
      'from': IsoDateRange.daysAgoStartIso(_rangeDays),
      'to': IsoDateRange.todayEndIso,
      'residenceId': residenceId,
    };

    // Silent GETs — controller shows a single error/empty state.
    final results = await Future.wait([
      _api.get(
        ApiEndpoints.dailyLogs,
        query: {...range, 'status': 'review', 'page': 1, 'limit': _pageSize},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.dailyLogs,
        query: {...range, 'status': 'missing', 'page': 1, 'limit': _pageSize},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.careFlags,
        query: {
          'state': 'open',
          'page': 1,
          'limit': _pageSize,
          'residenceId': residenceId,
        },
        silent: true,
      ),
      _api.get(
        ApiEndpoints.shiftHandovers,
        query: {
          'page': 1,
          'limit': _pageSize,
          'status': 'submitted',
          'residenceId': residenceId,
        },
        silent: true,
      ),
    ]);

    final review = results[0];
    final missing = results[1];
    final flags = results[2];
    var handovers = results[3];

    // If the submitted filter is empty/unavailable, still show recent handovers.
    if (handovers.isFailure ||
        (handovers.isSuccess &&
            JsonCodec.unwrapList(handovers.value).isEmpty)) {
      final fallbackHandovers = await _api.get(
        ApiEndpoints.shiftHandovers,
        query: {
          'page': 1,
          'limit': _pageSize,
          'residenceId': residenceId,
        },
        silent: true,
      );
      if (fallbackHandovers.isSuccess) {
        handovers = fallbackHandovers;
      }
    }

    final reviewOk = review.isSuccess;
    final missingOk = missing.isSuccess;
    final handoversOk = handovers.isSuccess;

    if (!reviewOk && !missingOk && !handoversOk) {
      return Result.failure(
        _friendlyFailure(
          review.error ?? missing.error ?? handovers.error,
          fallback: 'Could not load daily logs.',
        ),
      );
    }

    try {
      return Result.success(
        DailyLogsMapper.compose(
          reviewBody: reviewOk ? review.value : null,
          flagsBody: flags.isSuccess ? flags.value : null,
          missingBody: missingOk ? missing.value : null,
          handoversBody: handoversOk ? handovers.value : null,
          residenceName: _session.residenceName,
        ),
      );
    } catch (error) {
      return Result.failure(
        _friendlyFailure(
          ApiError(message: error.toString()),
          fallback: 'Could not parse daily logs from the server response.',
        ),
      );
    }
  }

  /// Prefer the session residence; otherwise use the first `GET /residences` row
  /// and cache it on the session for later screens.
  Future<String?> _resolveResidenceId() async {
    final existing = _session.residenceId?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 20},
      silent: true,
    );
    if (result.isFailure) return null;

    final rows = JsonCodec.unwrapList(result.value).whereType<Map>();
    for (final raw in rows) {
      final json = JsonCodec.asMap(raw);
      final id = JsonCodec.string(json['id'])?.trim();
      if (id == null || id.isEmpty) continue;
      final name = JsonCodec.string(json['name']);
      _session.applyStaffContext(residenceId: id, residenceName: name);
      return id;
    }
    return null;
  }

  AppError _friendlyFailure(AppError? error, {required String fallback}) {
    final message = (error?.message ?? '').trim();
    if (message.contains('subtype of type') ||
        message.contains('is not a subtype') ||
        message.startsWith('type \'')) {
      return ApiError(
        message:
            'Could not load daily logs. Check that a residence is selected, then try again.',
        statusCode: error is ApiError ? error.statusCode : null,
        code: error?.code,
      );
    }
    if (message.isEmpty ||
        message == 'Please try again in a moment.' ||
        message == 'Request failed') {
      return ApiError(message: fallback, code: error?.code);
    }
    return error ?? ApiError(message: fallback);
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
