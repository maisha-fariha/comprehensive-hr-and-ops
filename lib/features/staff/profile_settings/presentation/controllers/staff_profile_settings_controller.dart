import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/roles/user_session.dart';
import '../../data/mappers/staff_profile_mapper.dart';
import '../../domain/entities/staff_profile_settings_overview.dart';
import '../../domain/repositories/staff_profile_settings_repository.dart';

class StaffProfileSettingsController extends BaseController<StaffProfileSettingsOverview> {
  final StaffProfileSettingsRepository repository;

  StaffProfileSettingsController({required this.repository}) {
    // BUG_Report001: seed from the signed-in session so Profile always opens
    // immediately (even when `/mobile/me` or clients are slow/offline).
    _seedFromSession();
    loadOverview();
  }

  void _seedFromSession() {
    try {
      final session = Get.find<UserSession>();
      setSuccess(
        StaffProfileMapper.compose(
          session: session,
          clientsBody: const <dynamic>[],
        ),
      );
    } catch (_) {
      // Session not ready yet — [loadOverview] will populate shortly.
    }
  }

  final RxBool pushNotificationsEnabled = false.obs;
  final RxBool darkModeEnabled = false.obs;

  StaffProfileSettingsOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    setLoading(true);
    final result = await repository.getOverview();
    result.when(
      success: (overview) {
        pushNotificationsEnabled.value = overview.pushNotificationsEnabled;
        darkModeEnabled.value = overview.darkModeEnabled;
        setSuccess(overview);
      },
      failure: (error) {
        // Keep session-seeded profile if network refresh fails so the
        // Profile screen still opens with usable content (BUG_Report001).
        if (state.value.data == null) {
          setError(error.message);
        }
      },
    );
    setLoading(false);
  }

  void togglePushNotifications(bool value) => pushNotificationsEnabled.value = value;

  void toggleDarkMode(bool value) => darkModeEnabled.value = value;

  Future<void> submitSupportTicket(String message) async {
    final result = await repository.createSupportTicket(
      subject: 'Staff support',
      body: message,
    );
    result.when(
      success: (_) => Get.snackbar(
        'Message sent',
        'Support will follow up on your request.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not send',
      ),
    );
  }

  /// Returns `null` on success, otherwise the message for the dialog.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    return result.when(
      success: (_) => null,
      failure: (error) => AppErrorMapper.from(error).message,
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
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not save',
      ),
    );
  }

  @override
  Future<void> refresh() => loadOverview();
}
