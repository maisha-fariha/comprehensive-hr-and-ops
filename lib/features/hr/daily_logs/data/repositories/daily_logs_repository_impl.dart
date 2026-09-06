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
      'limit': 100,
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
      _api.get(
        ApiEndpoints.careFlags,
        query: {
          'state': 'open',
          'residenceId': ?residenceId,
        },
      ),
      _api.get(
        ApiEndpoints.dailyLogs,
        query: {...base, 'status': 'missing'},
      ),
      _api.get(ApiEndpoints.shiftHandovers, query: base),
    ]);

    if (extras[1].isFailure && extras[2].isFailure) {
      return Result.failure(
        extras[1].error ??
            const ApiError(message: 'Could not load daily log details.'),
      );
    }

    var missingBody = extras[1].isSuccess ? extras[1].value : null;
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
        flagsBody: extras[0].isSuccess ? extras[0].value : null,
        missingBody: missingBody,
        handoversBody: extras[2].isSuccess ? extras[2].value : null,
      ),
    );
  }
}
