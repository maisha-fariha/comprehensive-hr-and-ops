import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/repositories/family_profile_settings_repository.dart';
import '../mappers/family_profile_mapper.dart';

class FamilyProfileSettingsRepositoryImpl
    implements FamilyProfileSettingsRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyProfileSettingsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<FamilyProfileSettingsOverview>> getOverview() async {
    final result = await _api.get(ApiEndpoints.familyClients);
    return result.when(
      success: (body) async => Result.success(
        FamilyProfileMapper.compose(session: _session, clientsBody: body),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createSupportTicket({
    required String subject,
    required String body,
  }) async {
    final result = await _api.post(
      ApiEndpoints.tickets,
      data: {'subject': subject, 'body': body},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
