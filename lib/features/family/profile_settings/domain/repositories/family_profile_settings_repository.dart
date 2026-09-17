import 'package:gems_core/gems_core.dart';

import '../entities/family_notification_preference.dart';
import '../entities/family_profile_settings_overview.dart';
import '../entities/family_support_ticket.dart';
import '../entities/family_support_ticket_thread.dart';

abstract class FamilyProfileSettingsRepository {
  Future<Result<FamilyProfileSettingsOverview>> getOverview();

  Future<Result<String>> createSupportTicket({
    required String subject,
    required String body,
  });

  Future<Result<List<FamilySupportTicket>>> getSupportTickets();

  Future<Result<FamilySupportTicketThread>> getSupportTicketThread(
    String ticketId,
  );

  Future<Result<List<FamilyNotificationPreference>>>
      getNotificationPreferences();

  Future<Result<void>> updateNotificationPreferences(
    List<FamilyNotificationPreference> values,
  );

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
