import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/family_profile_settings_overview.dart';
import '../../domain/repositories/family_profile_settings_repository.dart';

/// GetX controller for the "Profile & Settings" screen.
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the two "App Settings"
/// toggle switches as local reactive state (mock-only — there's no backend
/// endpoint to persist them to yet).
class FamilyProfileSettingsController extends BaseController<FamilyProfileSettingsOverview> {
  final FamilyProfileSettingsRepository repository;

  FamilyProfileSettingsController({required this.repository}) {
    loadOverview();
  }

  final RxBool pushNotificationsEnabled = false.obs;
  final RxBool darkModeEnabled = false.obs;

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

  void togglePushNotifications(bool value) => pushNotificationsEnabled.value = value;

  void toggleDarkMode(bool value) => darkModeEnabled.value = value;

  Future<void> submitSupportTicket(String message) async {
    final result = await repository.createSupportTicket(
      subject: 'Family support',
      body: message,
    );
    result.when(
      success: (_) => Get.snackbar(
        'Message sent',
        'The care team will follow up on your request.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      failure: (error) => Get.snackbar(
        'Could not send',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
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
      failure: (error) => Get.snackbar(
        'Could not update password',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  Future<Map<String, bool>> loadNotificationPreferences() async {
    final result = await repository.getNotificationPreferences();
    return result.when(
      success: (values) => values,
      failure: (_) => const <String, bool>{},
    );
  }

  Future<void> saveNotificationPreferences(Map<String, bool> values) async {
    final result = await repository.updateNotificationPreferences(values);
    result.when(
      success: (_) => Get.snackbar(
        'Preferences saved',
        'Notification settings were updated.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      failure: (error) => Get.snackbar(
        'Could not save',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
