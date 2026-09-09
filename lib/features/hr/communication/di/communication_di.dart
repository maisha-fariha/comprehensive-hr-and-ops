import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../data/repositories/communication_repository_impl.dart';
import '../domain/repositories/communication_repository.dart';
import '../presentation/controllers/communication_controller.dart';

Future<void> setupHrCommunicationDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<CommunicationRepository>(
    factory: () => CommunicationRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );

  DIHelper.registerController<CommunicationController>(
    factory: () => CommunicationController(
      repository: getIt<CommunicationRepository>(),
    ),
  );
}
