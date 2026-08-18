import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/hr_profile_settings_repository_impl.dart';
import '../domain/repositories/hr_profile_settings_repository.dart';
import '../presentation/controllers/hr_profile_settings_controller.dart';

Future<void> setupHrProfileSettingsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<HrProfileSettingsRepository>(
    factory: () => HrProfileSettingsRepositoryImpl(),
  );

  DIHelper.registerController<HrProfileSettingsController>(
    factory: () => HrProfileSettingsController(repository: getIt<HrProfileSettingsRepository>()),
  );
}
