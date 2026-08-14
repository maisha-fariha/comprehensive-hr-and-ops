import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/staff_profile_settings_repository_impl.dart';
import '../domain/repositories/staff_profile_settings_repository.dart';
import '../presentation/controllers/staff_profile_settings_controller.dart';

Future<void> setupStaffProfileSettingsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffProfileSettingsRepository>(
    factory: () => StaffProfileSettingsRepositoryImpl(),
  );

  DIHelper.registerController<StaffProfileSettingsController>(
    factory: () => StaffProfileSettingsController(repository: getIt<StaffProfileSettingsRepository>()),
  );
}
