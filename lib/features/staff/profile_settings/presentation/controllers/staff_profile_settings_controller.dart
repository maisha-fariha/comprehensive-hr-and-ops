import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/media/app_file_picker.dart';
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
  final RxBool avatarBusy = false.obs;

  static const _avatarExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
  static const _avatarMaxBytes = 25 * 1024 * 1024;

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

  /// Picks a photo and sets it as the account picture (`PATCH /auth/avatar`).
  /// Same types and 25 MB cap as the web My profile page.
  Future<void> changeAvatar() async {
    if (avatarBusy.value) return;
    final picked = await AppFilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
      title: 'Profile photo',
      preferredCamera: CameraDevice.front,
    );
    final file = picked?.files.single;
    final path = file?.path;
    if (file == null || path == null || path.isEmpty) return;

    final ext = file.extension?.toLowerCase() ?? '';
    if (!_avatarExtensions.contains(ext)) {
      AppErrorDialog.showInfo(
        title: 'Unsupported photo',
        message: 'Choose a JPEG, PNG, WebP or HEIC image.',
      );
      return;
    }
    if (file.size > _avatarMaxBytes) {
      AppErrorDialog.showInfo(
        title: 'Photo too large',
        message: 'Choose an image up to 25 MB.',
      );
      return;
    }

    avatarBusy.value = true;
    final result = await repository.updateAvatar(
      filePath: path,
      fileName: file.name,
    );
    avatarBusy.value = false;
    result.when(
      success: (url) {
        if (url == null || url.trim().isEmpty) {
          AppErrorDialog.showInfo(
            title: 'Could not update photo',
            message: 'The server did not return the new photo. Please try again.',
          );
          return;
        }
        _session?.updateAvatarUrl(url);
        AppSnackbar.show('Photo updated', 'Your profile picture was changed.');
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not update photo',
      ),
    );
  }

  Future<void> removeAvatar() async {
    if (avatarBusy.value) return;
    avatarBusy.value = true;
    final result = await repository.removeAvatar();
    avatarBusy.value = false;
    result.when(
      success: (_) {
        _session?.updateAvatarUrl(null);
        AppSnackbar.show(
          'Photo removed',
          'Your staff record photo, or your initials, will be shown instead.',
        );
      },
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not remove photo',
      ),
    );
  }

  UserSession? get _session {
    try {
      return Get.find<UserSession>();
    } catch (_) {
      return null;
    }
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
