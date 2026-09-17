import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/family_notification_preference.dart';
import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/entities/family_support_ticket.dart';
import '../../domain/entities/family_support_ticket_thread.dart';
import '../../domain/repositories/family_profile_settings_repository.dart';
import '../mappers/family_profile_mapper.dart';

class FamilyProfileSettingsRepositoryImpl
    implements FamilyProfileSettingsRepository {
  final AppApiClient _api;
  final UserSession _session;
  final AuthRepository _auth;

  FamilyProfileSettingsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
    required AuthRepository auth,
  })  : _api = api,
        _session = session,
        _auth = auth;

  @override
  Future<Result<FamilyProfileSettingsOverview>> getOverview() async {
    // Refresh identity from GET /mobile/me so name/email/relationship stay current.
    final me = await _auth.fetchMe(silent: true);
    me.when(
      success: _session.applyProfile,
      failure: (_) {},
    );

    final result = await _api.get(ApiEndpoints.familyClients);
    return result.when(
      success: (body) async => Result.success(
        FamilyProfileMapper.compose(session: _session, clientsBody: body),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> createSupportTicket({
    required String subject,
    required String body,
  }) async {
    final result = await _api.post(
      ApiEndpoints.tickets,
      data: {
        'subject': subject,
        'priority': 'low',
        'body': body,
      },
    );
    return result.when(
      success: (response) async {
        final json = JsonCodec.unwrapMap(response);
        final id = JsonCodec.string(json['id']);
        if (id == null || id.isEmpty) {
          return Result.failure(
            const UnknownError(message: 'Ticket was created without an id.'),
          );
        }
        return Result.success(id);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FamilySupportTicket>>> getSupportTickets() async {
    final result = await _api.get(ApiEndpoints.familyTickets);
    return result.when(
      success: (body) async =>
          Result.success(FamilyProfileMapper.ticketsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<FamilySupportTicketThread>> getSupportTicketThread(
    String ticketId,
  ) async {
    final ticketResult = await _api.get(ApiEndpoints.familyTicketById(ticketId));
    if (ticketResult.isFailure) {
      return Result.failure(ticketResult.error!);
    }

    final messagesResult =
        await _api.get(ApiEndpoints.familyTicketMessages(ticketId));
    // Ticket detail alone is enough if messages fail or are embedded.
    final messagesBody = messagesResult.isSuccess ? messagesResult.value : null;

    return Result.success(
      FamilyProfileMapper.threadFrom(
        ticketBody: ticketResult.value,
        messagesBody: messagesBody,
      ),
    );
  }

  @override
  Future<Result<void>> replyToSupportTicket({
    required String ticketId,
    required String body,
  }) async {
    final result = await _api.post(
      ApiEndpoints.ticketMessages(ticketId),
      data: {'body': body},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> closeSupportTicket(String ticketId) async {
    final result = await _api.post(
      ApiEndpoints.ticketClose(ticketId),
      data: const <String, dynamic>{},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FamilyNotificationPreference>>>
      getNotificationPreferences() async {
    final prefsResult = await _api.get(ApiEndpoints.notificationPreferences);
    if (prefsResult.isFailure) {
      return Result.failure(prefsResult.error!);
    }

    final saved =
        FamilyProfileMapper.notificationPreferencesFrom(prefsResult.value);

    final eventsResult =
        await _api.get(ApiEndpoints.notificationPreferenceEvents);
    if (eventsResult.isFailure) {
      // Saved prefs alone are still usable when the catalog is unavailable.
      if (saved.isNotEmpty) return Result.success(saved);
      return Result.failure(eventsResult.error!);
    }

    return Result.success(
      FamilyProfileMapper.mergePreferencesWithEvents(
        saved: saved,
        eventsBody: eventsResult.value,
      ),
    );
  }

  @override
  Future<Result<void>> updateNotificationPreferences(
    List<FamilyNotificationPreference> values,
  ) async {
    final result = await _api.put(
      ApiEndpoints.notificationPreferencesBulk,
      data: {
        'preferences': values.map((item) => item.toJson()).toList(),
      },
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
