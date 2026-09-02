import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../mappers/incidents_mapper.dart';

class IncidentsRepositoryImpl implements IncidentsRepository {
  final AppApiClient _api;
  final UserSession _session;

  IncidentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<IncidentsBoard>> getBoard() async {
    final residenceId = _session.residenceId;
    final list = await _api.get(
      ApiEndpoints.incidents,
      query: {
        'page': 1,
        'limit': 50,
        'residenceId': ?residenceId,
      },
    );
    if (list.isFailure) {
      return Result.failure(
        list.error ?? const ApiError(message: 'Could not load incidents.'),
      );
    }
    final summary = await _api.get(ApiEndpoints.incidentsSummary);
    return Result.success(
      IncidentsMapper.compose(
        listBody: list.value,
        summaryBody: summary.value,
      ),
    );
  }
}
