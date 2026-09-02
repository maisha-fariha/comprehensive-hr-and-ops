import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/scheduling_overview.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../mappers/scheduling_mapper.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  final AppApiClient _api;
  final UserSession _session;

  SchedulingRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<SchedulingOverview>> getOverview() async {
    final residenceId = _session.residenceId;
    final weekQuery = <String, dynamic>{
      'from': IsoDateRange.weekStartIso,
      'to': IsoDateRange.weekEndIso,
      'page': 1,
      'limit': 100,
      'residenceId': ?residenceId,
    };

    final results = await Future.wait([
      _api.get(ApiEndpoints.shifts, query: weekQuery),
      _api.get(
        ApiEndpoints.shifts,
        query: {
          'status': 'open',
          'from': IsoDateRange.weekStartIso,
          'to': IsoDateRange.weekEndIso,
          'residenceId': ?residenceId,
        },
      ),
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: const {'status': 'awaiting_peer,awaiting_manager'},
      ),
      _api.get(
        ApiEndpoints.shiftSwaps,
        query: const {'status': 'approved'},
      ),
    ]);

    final week = results[0];
    if (week.isFailure) {
      return Result.failure(
        week.error ?? const ApiError(message: 'Could not load the schedule.'),
      );
    }

    return Result.success(
      SchedulingMapper.compose(
        weekBody: week.value,
        openBody: results[1].value,
        pendingSwapsBody: results[2].value,
        approvedSwapsBody: results[3].value,
      ),
    );
  }
}
