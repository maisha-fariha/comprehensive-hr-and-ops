import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/entities/shift_residence_option.dart';
import '../../domain/entities/shift_staff_option.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../mappers/scheduling_mapper.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  static const _pageSize = 100;
  static const _maxPages = 5;

  final AppApiClient _api;
  final UserSession _session;

  SchedulingRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<SchedulingOverview>> getOverview({
    DateTime? weekOf,
    DateTime? selectedDay,
  }) async {
    final residenceId = _session.residenceId;
    final anchor = weekOf ?? DateTime.now();
    final from = IsoDateRange.startOfWeek(anchor).toUtc().toIso8601String();
    final to = IsoDateRange.endOfWeek(anchor).toUtc().toIso8601String();

    final week = await _fetchAllPages(
      path: ApiEndpoints.shifts,
      baseQuery: {
        'from': from,
        'to': to,
        'residenceId': ?residenceId,
      },
    );
    if (week.isFailure) {
      return Result.failure(
        week.error ?? const ApiError(message: 'Could not load the schedule.'),
      );
    }

    final swapBase = <String, dynamic>{
      'from': from,
      'to': to,
      'residenceId': ?residenceId,
    };

    final results = await Future.wait([
      _fetchAllPages(
        path: ApiEndpoints.shifts,
        baseQuery: {
          'status': 'open',
          'from': from,
          'to': to,
          'residenceId': ?residenceId,
        },
      ),
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: {
          ...swapBase,
          'status': 'awaiting_peer,awaiting_manager',
          'page': 1,
          'limit': _pageSize,
        },
      ),
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: {
          ...swapBase,
          'status': 'approved',
          'page': 1,
          'limit': _pageSize,
        },
      ),
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: {
          ...swapBase,
          'status': 'declined,rejected',
          'page': 1,
          'limit': _pageSize,
        },
      ),
    ]);

    for (final result in results) {
      if (result.isFailure) {
        return Result.failure(
          result.error ??
              const ApiError(message: 'Could not load the full schedule.'),
        );
      }
    }

    return Result.success(
      SchedulingMapper.compose(
        weekBody: week.value,
        openBody: results[0].value,
        pendingSwapsBody: results[1].value,
        approvedSwapsBody: results[2].value,
        declinedSwapsBody: results[3].value,
        weekOf: anchor,
        selectedDay: selectedDay,
      ),
    );
  }

  /// Walks `page=1..n` until a short page is returned (or [_maxPages]).
  Future<Result<List<dynamic>>> _fetchAllPages({
    required String path,
    required Map<String, dynamic> baseQuery,
  }) async {
    final all = <dynamic>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = await _api.get(
        path,
        query: {
          ...baseQuery,
          'page': page,
          'limit': _pageSize,
        },
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load shifts.'),
        );
      }
      final rows = JsonCodec.unwrapList(result.value);
      all.addAll(rows);
      if (rows.length < _pageSize) break;
    }
    return Result.success(all);
  }

  @override
  Future<Result<List<ShiftResidenceOption>>> getResidences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(SchedulingMapper.residencesFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ShiftStaffOption>>> searchStaff({
    String? search,
    String? residenceId,
  }) async {
    final trimmed = search?.trim() ?? '';
    final scopedResidenceId = residenceId ?? _session.residenceId;

    final result = await _api.get(
      ApiEndpoints.staff,
      query: {
        'page': 1,
        'limit': _pageSize,
        if (trimmed.isNotEmpty) 'search': trimmed,
        'residenceId': ?scopedResidenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(SchedulingMapper.staffFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> decideShiftSwap({
    required String swapId,
    required bool approve,
  }) async {
    final result = await _api.post(
      ApiEndpoints.shiftSwapDecide(swapId),
      data: {
        'decision': approve ? 'approved' : 'rejected',
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
