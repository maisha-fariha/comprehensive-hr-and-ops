import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/staff_profile_settings_overview.dart';
import '../../domain/repositories/staff_profile_settings_repository.dart';
import '../mappers/staff_profile_mapper.dart';

class StaffProfileSettingsRepositoryImpl
    implements StaffProfileSettingsRepository {
  final AppApiClient _api;
  final UserSession _session;
  final AuthRepository _auth;

  StaffProfileSettingsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required AuthRepository auth,
  })  : _api = api,
        _session = session,
        _auth = auth;

  @override
  Future<Result<StaffProfileSettingsOverview>> getOverview() async {
    // Always refresh identity from GET /mobile/me so the card matches
    // the signed-in user (not a stale cached session / previous login).
    final me = await _auth.fetchMe(silent: true);
    if (me.isSuccess && me.value != null) {
      _session.applyProfile(me.value!);
    }

    Result<dynamic> clients = Result.success(<dynamic>[]);
    if (_session.canAccessClients) {
      clients = await _api.get(
        ApiEndpoints.clients,
        query: {
          'assignedToMe': true,
          'page': 1,
          'limit': 50,
          'residenceId': ?_session.residenceId,
        },
        silent: true,
      );
    }

    return Result.success(
      StaffProfileMapper.compose(
        session: _session,
        clientsBody: clients.isSuccess ? clients.value : const <dynamic>[],
      ),
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

  @override
  Future<Result<Map<String, bool>>> getNotificationPreferences() async {
    final result = await _api.get(ApiEndpoints.notificationPreferences);
    return result.when(
      success: (body) async {
        final json = JsonCodec.unwrapMap(body);
        final nested = JsonCodec.mapAt(json, 'preferences') ?? json;
        final values = <String, bool>{};
        nested.forEach((key, value) {
          final parsed = JsonCodec.boolean(value);
          if (parsed != null) values[key] = parsed;
        });
        return Result.success(values);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> updateNotificationPreferences(
    Map<String, bool> values,
  ) async {
    final result = await _api.patch(
      ApiEndpoints.notificationPreferences,
      data: values,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _api.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
