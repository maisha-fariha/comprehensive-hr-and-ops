import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../domain/entities/staff_schedule_overview.dart';
import '../../domain/repositories/staff_schedule_repository.dart';
import '../mappers/staff_schedule_mapper.dart';

class StaffScheduleRepositoryImpl implements StaffScheduleRepository {
  final AppApiClient _api;

  StaffScheduleRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<StaffScheduleOverview>> getOverview() async {
    final query = <String, dynamic>{
      'from': IsoDateRange.weekStartIso,
      'to': IsoDateRange.weekEndIso,
      'page': 1,
      'limit': 20,
    };
    final results = await Future.wait([
      _api.get(ApiEndpoints.shifts, query: {...query, 'mine': true}),
      _api.get(ApiEndpoints.shifts, query: {...query, 'status': 'open'}),
    ]);
    if (results[0].isFailure) {
      return Result.failure(
        results[0].error ??
            const ApiError(message: 'Could not load your shifts.'),
      );
    }
    return Result.success(
      StaffScheduleMapper.compose(
        mineBody: results[0].value,
        openBody: results[1].value,
      ),
    );
  }

  @override
  Future<Result<void>> bidOnShift(String shiftId) async {
    final result = await _api.post(ApiEndpoints.shiftBids(shiftId), data: {});
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
