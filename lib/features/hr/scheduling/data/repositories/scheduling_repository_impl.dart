import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/scheduling_enums.dart';
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
    String? residenceId,
    ShiftStatusFilter? status,
    bool mine = false,
  }) async {
    final scopedResidenceId = residenceId ?? _session.residenceId;
    final anchor = weekOf ?? DateTime.now();
    final from = IsoDateRange.startOfWeek(anchor).toUtc().toIso8601String();
    final to = IsoDateRange.endOfWeek(anchor).toUtc().toIso8601String();

    final weekResult = await _fetchAllPages(
      path: ApiEndpoints.shifts,
      baseQuery: {
        'from': from,
        'to': to,
        'residenceId': ?scopedResidenceId,
        if (mine) 'mine': true,
      },
    );
    if (weekResult.isFailure) {
      return Result.failure(
        weekResult.error ??
            const ApiError(message: 'Could not load the schedule.'),
      );
    }
    final week = _applyShiftFilters(
      weekResult.value ?? const [],
      residenceId: residenceId,
      status: status,
    );

    final swapBase = <String, dynamic>{
      'from': from,
      'to': to,
      'residenceId': ?scopedResidenceId,
    };

    final results = await Future.wait([
      _fetchAllPages(
        path: ApiEndpoints.shifts,
        baseQuery: {
          'status': 'open',
          'from': from,
          'to': to,
          'residenceId': ?scopedResidenceId,
          if (mine) 'mine': true,
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
        weekBody: week,
        openBody: _applyShiftFilters(
          results[0].value as List<dynamic>? ?? const [],
          residenceId: residenceId,
        ),
        pendingSwapsBody: results[1].value,
        approvedSwapsBody: results[2].value,
        declinedSwapsBody: results[3].value,
        weekOf: anchor,
        selectedDay: selectedDay,
      ),
    );
  }

  /// Client-side guard so filters still apply when the API ignores the
  /// `residenceId` query or returns every lifecycle state.
  List<dynamic> _applyShiftFilters(
    List<dynamic> rows, {
    String? residenceId,
    ShiftStatusFilter? status,
  }) {
    if (residenceId == null && status == null) return rows;
    return rows.where((row) {
      final json = JsonCodec.asMap(row);
      if (residenceId != null) {
        final rowResidence = JsonCodec.string(
          json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
        );
        if (rowResidence != null && rowResidence != residenceId) return false;
      }
      if (status != null) {
        final rowStatus = JsonCodec.string(json['status'])?.toLowerCase();
        if (rowStatus == null || !status.apiValues.contains(rowStatus)) {
          return false;
        }
      }
      return true;
    }).toList();
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
  Future<Result<List<ShiftStaffOption>>> getStaffOptions() async {
    final result = await _api.get(
      ApiEndpoints.staff,
      query: {'page': 1, 'limit': _pageSize},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(SchedulingMapper.staffFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<int>> createShift(Map<String, dynamic> payload) async {
    final result = await _api.post(
      ApiEndpoints.shifts,
      data: payload,
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(_createdCount(body)),
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

  /// `POST /shifts` answers with one shift, or a list for a recurring series.
  int _createdCount(dynamic body) {
    final data = body is Map ? body['data'] ?? body : body;
    if (data is List) return data.isEmpty ? 1 : data.length;
    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      return items.isEmpty ? 1 : items.length;
    }
    return 1;
  }
}
