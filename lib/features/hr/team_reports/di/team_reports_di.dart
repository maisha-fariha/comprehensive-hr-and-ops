import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';

import '../data/repositories/team_reports_repository_impl.dart';
import '../domain/repositories/team_reports_repository.dart';
import '../presentation/controllers/team_reports_controller.dart';

/// Registers the HR "Team & Reports" feature's repository + controller in
/// the shared `get_it` service locator, mirroring the pattern used by every
/// other feature in the `flutter_gems` reference app
/// (see `flutter_gems/lib/di/todo/todo_di.dart`).
Future<void> setupHrTeamReportsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<TeamReportsRepository>(
    factory: () => TeamReportsRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<TeamReportsController>(
    factory: () => TeamReportsController(repository: getIt<TeamReportsRepository>()),
  );
}
