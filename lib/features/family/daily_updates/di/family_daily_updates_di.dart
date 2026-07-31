import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../data/repositories/family_daily_updates_repository_impl.dart';
import '../domain/repositories/family_daily_updates_repository.dart';
import '../presentation/controllers/family_daily_updates_controller.dart';

/// Registers the Family Daily Updates feature's repository + controller in
/// the shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the app (see `lib/features/hr/dashboard/di/dashboard_di.dart`).
Future<void> setupFamilyDailyUpdatesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyDailyUpdatesRepository>(
    factory: () => FamilyDailyUpdatesRepositoryImpl(),
  );

  DIHelper.registerController<FamilyDailyUpdatesController>(
    factory: () => FamilyDailyUpdatesController(repository: getIt<FamilyDailyUpdatesRepository>()),
  );
}
