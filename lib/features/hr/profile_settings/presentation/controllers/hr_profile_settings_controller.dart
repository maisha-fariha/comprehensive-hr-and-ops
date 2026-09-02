import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../domain/entities/hr_profile_settings_overview.dart';
import '../../domain/repositories/hr_profile_settings_repository.dart';

class HrProfileSettingsController extends BaseController<HrProfileSettingsOverview> {
  final HrProfileSettingsRepository repository;

  HrProfileSettingsController({required this.repository}) {
    loadOverview();
  }

  final RxBool pushNotificationsEnabled = false.obs;
  final RxBool darkModeEnabled = false.obs;

  HrProfileSettingsOverview? get overview => state.value.data;

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
      subject: 'Manager support',
      body: message,
    );
    result.when(
      success: (_) => Get.snackbar(
        'Message sent',
        'Support will follow up on your request.',
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
