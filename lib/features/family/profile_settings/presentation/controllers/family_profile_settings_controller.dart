import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../appointments/presentation/controllers/family_appointments_controller.dart';
import '../../../daily_updates/presentation/controllers/family_daily_updates_controller.dart';
import '../../../dashboard/presentation/controllers/family_dashboard_controller.dart';
import '../../domain/entities/family_linked_client.dart';
import '../../domain/entities/family_notification_preference.dart';
import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/entities/family_support_ticket.dart';
import '../../domain/entities/family_support_ticket_thread.dart';
import '../../domain/repositories/family_profile_settings_repository.dart';

/// GetX controller for the "Profile & Settings" screen.
class FamilyProfileSettingsController
    extends BaseController<FamilyProfileSettingsOverview> {
  final FamilyProfileSettingsRepository repository;

  FamilyProfileSettingsController({required this.repository}) {
    loadOverview();
  }

  final RxBool pushNotificationsEnabled = false.obs;
  final RxBool darkModeEnabled = false.obs;
  final RxList<FamilySupportTicket> supportTickets = <FamilySupportTicket>[].obs;
  final RxBool supportTicketsLoading = false.obs;
  final RxnString supportTicketsError = RxnString();

  FamilyProfileSettingsOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: (overview) {
        pushNotificationsEnabled.value = overview.pushNotificationsEnabled;
        darkModeEnabled.value = overview.darkModeEnabled;
        setSuccess(overview);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void togglePushNotifications(bool value) =>
      pushNotificationsEnabled.value = value;

  void toggleDarkMode(bool value) => darkModeEnabled.value = value;

  /// Switches the active linked client and refreshes client-scoped family data.
  Future<void> switchLinkedClient(FamilyLinkedClient client) async {
    if (client.id.isEmpty) return;
    final session = Get.find<UserSession>();
    final alreadySelected = session.selectedClientId == client.id;
    session.selectClient(client.id);

    await Future.wait([
      if (Get.isRegistered<FamilyDashboardController>())
        Get.find<FamilyDashboardController>().refresh(),
      if (Get.isRegistered<FamilyDailyUpdatesController>())
        Get.find<FamilyDailyUpdatesController>().refresh(),
      if (Get.isRegistered<FamilyAppointmentsController>())
        Get.find<FamilyAppointmentsController>().refresh(),
    ]);

    Get.snackbar(
      alreadySelected ? 'Client selected' : 'Client switched',
      'Now viewing ${client.name}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Creates a ticket via POST /tickets, then refreshes GET /family/tickets.
  /// Returns the new ticket id on success.
  Future<String?> submitSupportTicket(String message) async {
    final result = await repository.createSupportTicket(
      subject: 'Family support',
      body: message,
    );
    if (result.isFailure) {
      AppErrorDialog.showResultError(
        result.error!,
        fallbackTitle: 'Could not send',
      );
      return null;
    }
    await loadSupportTickets();
    Get.snackbar(
      'Message sent',
      'The care team will follow up on your request.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return result.value;
  }

  Future<void> loadSupportTickets() async {
    supportTicketsLoading.value = true;
    supportTicketsError.value = null;
    final result = await repository.getSupportTickets();
    result.when(
      success: (tickets) {
        supportTickets.assignAll(tickets);
      },
      failure: (error) {
        supportTicketsError.value = error.message;
      },
    );
    supportTicketsLoading.value = false;
  }

  Future<FamilySupportTicketThread?> loadSupportTicketThread(
    String ticketId,
  ) async {
    final result = await repository.getSupportTicketThread(ticketId);
    return result.when(
      success: (thread) => thread,
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load ticket',
        );
        return null;
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    result.when(
      success: (_) => Get.snackbar(
        'Password updated',
        'Use your new password the next time you sign in.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update password',
      ),
    );
  }

  Future<List<FamilyNotificationPreference>> loadNotificationPreferences() async {
    final result = await repository.getNotificationPreferences();
    return result.when(
      success: (values) => values,
      failure: (_) => const <FamilyNotificationPreference>[],
    );
  }

  Future<void> saveNotificationPreferences(
    List<FamilyNotificationPreference> values,
  ) async {
    final result = await repository.updateNotificationPreferences(values);
    result.when(
      success: (_) => Get.snackbar(
        'Preferences saved',
        'Notification settings were updated.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not save',
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
