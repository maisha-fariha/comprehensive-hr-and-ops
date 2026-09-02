import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_dashboard_overview.dart';
import '../../domain/repositories/family_dashboard_repository.dart';
import '../mappers/family_home_mapper.dart';

class FamilyDashboardRepositoryImpl implements FamilyDashboardRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyDashboardRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<FamilyDashboardOverview>> getOverview() async {
    final home = await _api.get(ApiEndpoints.familyHome);
    if (home.isFailure) {
      return Result.failure(
        home.error ?? const ApiError(message: 'Could not load family home.'),
      );
    }

    Result<dynamic>? updates;
    final homeJson = JsonCodec.unwrapMap(home.value);
    final clients = JsonCodec.listAt(homeJson, 'linkedClients');
    var clientId = _session.selectedClientId;
    if ((clientId == null || clientId.isEmpty) &&
        clients.isNotEmpty &&
        clients.first is Map) {
      clientId = JsonCodec.string(JsonCodec.asMap(clients.first as Map)['id']);
    }
    final visibility = JsonCodec.mapAt(homeJson, 'visibility') ?? {};
    final showLogs = JsonCodec.boolean(visibility['dailyLogs']) ?? true;
    if (clientId != null && clientId.isNotEmpty && showLogs) {
      updates = await _api.get(ApiEndpoints.familyDailyUpdates(clientId));
    }

    return Result.success(
      FamilyHomeMapper.compose(
        session: _session,
        homeBody: home.value,
        updatesBody: updates?.value,
      ),
    );
  }
}
