import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_daily_updates_overview.dart';
import '../../domain/repositories/family_daily_updates_repository.dart';
import '../mappers/family_daily_updates_mapper.dart';

class FamilyDailyUpdatesRepositoryImpl implements FamilyDailyUpdatesRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyDailyUpdatesRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<FamilyDailyUpdatesOverview>> getOverview() async {
    final clientId = _session.selectedClientId;
    if (clientId == null || clientId.isEmpty) {
      return Result.success(
        const FamilyDailyUpdatesOverview(
          screenTitle: 'Daily Updates',
          screenSubtitle: 'Only approved updates are shown.',
          dateSectionLabel: 'Today',
          entries: [],
          footerNote:
              'Link a client on Home before daily updates can be loaded.',
        ),
      );
    }
    final result = await _api.get(ApiEndpoints.familyDailyUpdates(clientId));
    return result.when(
      success: (body) async =>
          Result.success(FamilyDailyUpdatesMapper.fromBody(body)),
      failure: (error) async => Result.failure(error),
    );
  }
}
