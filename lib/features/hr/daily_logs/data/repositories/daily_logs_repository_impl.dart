import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_logs_overview.dart';
import '../../domain/repositories/daily_logs_repository.dart';
import '../mappers/daily_logs_mapper.dart';

class DailyLogsRepositoryImpl implements DailyLogsRepository {
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
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'page': 1,
      'limit': 50,
      'residenceId': ?residenceId,
    };

    final review = await _api.get(
      ApiEndpoints.dailyLogs,
      query: {...base, 'status': 'review'},
    );
    if (review.isFailure) {
      return Result.failure(
        review.error ?? const ApiError(message: 'Could not load daily logs.'),
      );
    }

    final extras = await Future.wait([
      _api.get(ApiEndpoints.careFlags, query: const {'state': 'open'}),
      _api.get(
        ApiEndpoints.dailyLogs,
        query: {...base, 'status': 'missing'},
      ),
      _api.get(ApiEndpoints.shiftHandovers, query: base),
    ]);

    var missingBody = extras[1].value;
    if (JsonCodec.unwrapList(missingBody).isEmpty) {
      final overdue = await _api.get(
        ApiEndpoints.dailyLogs,
        query: {...base, 'status': 'overdue'},
      );
      if (overdue.isSuccess) missingBody = overdue.value;
    }

    return Result.success(
      DailyLogsMapper.compose(
        reviewBody: review.value,
        flagsBody: extras[0].value,
        missingBody: missingBody,
        handoversBody: extras[2].value,
      ),
    );
  }
}
