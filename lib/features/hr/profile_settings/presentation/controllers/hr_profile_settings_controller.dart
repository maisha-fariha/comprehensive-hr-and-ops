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

  @override
  Future<void> refresh() => loadOverview();
}
