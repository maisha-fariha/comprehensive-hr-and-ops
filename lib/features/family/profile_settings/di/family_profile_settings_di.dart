import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_profile_settings_repository_impl.dart';
import '../domain/repositories/family_profile_settings_repository.dart';
import '../presentation/controllers/family_profile_settings_controller.dart';

/// Registers the Family "Profile & Settings" feature's repository +
/// controller in the shared `get_it` service locator, mirroring the pattern
/// used by every HR/Staff feature module (see
/// `lib/features/hr/dashboard/di/dashboard_di.dart`).
///
/// NOTE: unlike the HR feature DI files, this is intentionally **not**
/// wired into `lib/core/di/service_locator.dart` yet — call this from the
/// app's startup once the Family portal's "More" hub is assembled.
Future<void> setupFamilyProfileSettingsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyProfileSettingsRepository>(
    factory: () => FamilyProfileSettingsRepositoryImpl(),
  );

  DIHelper.registerController<FamilyProfileSettingsController>(
    factory: () => FamilyProfileSettingsController(repository: getIt<FamilyProfileSettingsRepository>()),
  );
}
