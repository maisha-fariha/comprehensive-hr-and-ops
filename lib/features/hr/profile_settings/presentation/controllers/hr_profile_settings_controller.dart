import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:gems_data_layer/gems_data_layer.dart';

import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/errors/app_error_mapper.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';

import '../../domain/entities/hr_profile_settings_overview.dart';
import '../../domain/repositories/hr_profile_settings_repository.dart';
import '../../../../../core/media/app_file_picker.dart';

class HrProfileSettingsController extends BaseController<HrProfileSettingsOverview> {
  final HrProfileSettingsRepository repository;

  HrProfileSettingsController({required this.repository}) {
    loadOverview();
  }

  final RxBool pushNotificationsEnabled = false.obs;
  final RxBool darkModeEnabled = false.obs;

  HrProfileSettingsOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview();
    if (generation != _loadGeneration) return;
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

  int _loadGeneration = 0;

  void togglePushNotifications(bool value) => pushNotificationsEnabled.value = value;

  void toggleDarkMode(bool value) => darkModeEnabled.value = value;

  Future<void> submitSupportTicket(String message) async {
    final result = await repository.createSupportTicket(
      subject: 'Manager support',
      body: message,
    );
    result.when(
      success: (_) => AppSnackbar.show(
        'Message sent',
        'Support will follow up on your request.',
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
      failure: (error) {
        AppErrorDialog.showResultError(
          error,
          fallbackTitle: 'Could not load preferences',
        );
        return const <String, bool>{};
      },
    );
  }

  Future<void> saveNotificationPreferences(Map<String, bool> values) async {
    final result = await repository.updateNotificationPreferences(values);
    result.when(
      success: (_) => AppSnackbar.show(
        'Preferences saved',
        'Notification settings were updated.',
      ),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not save',
      ),
    );
  }

  static const _avatarExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
  static const _avatarMaxBytes = 2 * 1024 * 1024;

  final RxBool avatarBusy = false.obs;

  /// Picks an image (JPEG, PNG, WebP or HEIC, up to 2 MB) and sets it as the
  /// profile photo.
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
        message: 'Choose an image up to 2 MB.',
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
        if (url == null) {
          AppErrorDialog.showInfo(
            title: 'Could not update photo',
            message: 'The server did not return the new photo. Please try again.',
          );
          return;
        }
        _session?.updateAvatarUrl(url);
        AppSnackbar.show(
          'Photo updated',
          'Your profile picture was changed.',
        );
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
          'Your initials will be shown instead.',
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

  @override
  Future<void> refresh() => loadOverview();
}
