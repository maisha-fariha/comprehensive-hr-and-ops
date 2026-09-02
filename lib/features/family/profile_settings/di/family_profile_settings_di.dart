import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/family_profile_settings_repository_impl.dart';
import '../domain/repositories/family_profile_settings_repository.dart';
import '../presentation/controllers/family_profile_settings_controller.dart';

Future<void> setupFamilyProfileSettingsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyProfileSettingsRepository>(
    factory: () => FamilyProfileSettingsRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<FamilyProfileSettingsController>(
    factory: () => FamilyProfileSettingsController(
      repository: getIt<FamilyProfileSettingsRepository>(),
    ),
  );
}
