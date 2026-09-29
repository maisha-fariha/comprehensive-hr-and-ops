import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/handovers_repository_impl.dart';
import '../domain/repositories/handovers_repository.dart';
import '../presentation/controllers/handovers_controller.dart';

Future<void> setupHrHandoversDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<HandoversRepository>(
    factory: () => HandoversRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<HandoversController>(
    factory: () => HandoversController(
      repository: getIt<HandoversRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
