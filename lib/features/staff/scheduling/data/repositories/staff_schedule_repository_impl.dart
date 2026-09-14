import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/entities/staff_shift.dart';
import '../../domain/repositories/staff_schedule_repository.dart';
import '../mappers/staff_schedule_mapper.dart';

class StaffScheduleRepositoryImpl implements StaffScheduleRepository {
  static const _pageLimit = 20;

  final AppApiClient _api;
  final UserSession _session;

  StaffScheduleRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffScheduleOverview>> getOverview({
    DateTime? weekStart,
    DateTime? selectedDate,
  }) async {
    final start = IsoDateRange.startOfWeek(weekStart ?? DateTime.now());
    final end = start.add(const Duration(days: 7));
    // B2: appointments are nurse / caregiver only — never housekeeper / other.
    final includeAppointments = _session.canSeeStaffScheduleAppointments;

    final futures = <Future<Result<dynamic>>>[
      // B2: weekly My Shifts
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'mine': true,
          'from': start.toUtc().toIso8601String(),
          'to': end.toUtc().toIso8601String(),
          'page': 1,
          'limit': _pageLimit,
        },
      ),
      // B2: Open Shift Requests
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'status': 'open',
          'page': 1,
          'limit': _pageLimit,
        },
      ),
      // B2: my swap list — active requests only (not settled history)
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: {
          'mine': true,
          'status': 'awaiting_peer,awaiting_manager',
          'page': 1,
          'limit': _pageLimit,
        },
      ),
    ];

    if (includeAppointments) {
      // B2: Upcoming Appointments (nurse / caregiver)
      futures.add(
        _api.get(
          ApiEndpoints.appointments,
          query: {
            'page': 1,
            'limit': _pageLimit,
          },
        ),
      );
    }

    final results = await Future.wait(futures);
    if (results[0].isFailure) {
      return Result.failure(
        results[0].error ??
            const ApiError(message: 'Could not load your shifts.'),
      );
    }

    final warnings = <String>[];
    dynamic openBody = const [];
    if (results[1].isSuccess) {
      openBody = results[1].value;
    } else {
      warnings.add('Open shift requests could not be loaded.');
    }

    dynamic swapsBody = const [];
    if (results[2].isSuccess) {
      swapsBody = results[2].value;
    } else {
      warnings.add('Swap requests could not be loaded.');
    }

    dynamic appointmentsBody;
    if (includeAppointments && results.length > 3) {
      if (results[3].isSuccess) {
        appointmentsBody = results[3].value;
      } else {
        warnings.add('Appointments could not be loaded.');
      }
    }

    return Result.success(
      StaffScheduleMapper.compose(
        mineBody: results[0].value,
        openBody: openBody,
        swapsBody: swapsBody,
        appointmentsBody: appointmentsBody,
        weekStart: start,
        selectedDate: selectedDate,
        currentStaffId: _session.staffId ?? _session.userId,
        loadWarnings: warnings,
      ),
    );
  }

  @override
  Future<Result<StaffShift>> getShiftDetail(String shiftId) async {
    final result = await _api.get(ApiEndpoints.shiftById(shiftId));
    return result.when(
      success: (body) async {
        final map = JsonCodec.unwrapMap(body);
        return Result.success(StaffScheduleMapper.shiftFromJson(map));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> bidOnShift(String shiftId, {String? note}) async {
    final staffId = _session.staffId ?? _session.userId;
    final data = <String, dynamic>{
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final result = await _api.post(
      ApiEndpoints.shiftBids(shiftId),
      data: data,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> requestSwap({
    required String fromShiftId,
    String? note,
    String? targetStaffId,
    String? toShiftId,
  }) async {
    final data = <String, dynamic>{
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (targetStaffId != null && targetStaffId.isNotEmpty)
        'targetStaffId': targetStaffId,
      if (toShiftId != null && toShiftId.isNotEmpty) 'toShiftId': toShiftId,
    };
    final result = await _api.post(
      ApiEndpoints.shiftSwapRequests(fromShiftId),
      data: data,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> respondToSwap({
    required String swapId,
    required bool accepted,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'response': accepted ? 'accepted' : 'declined',
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final result = await _api.post(
      ApiEndpoints.shiftSwapRespond(swapId),
      data: data,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> cancelSwap(String swapId) async {
    final result = await _api.post(ApiEndpoints.shiftSwapCancel(swapId));
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
