import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/ai_alerts_repository_impl.dart';
import '../domain/repositories/ai_alerts_repository.dart';
import '../presentation/controllers/ai_alerts_controller.dart';

Future<void> setupHrAiAlertsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<AiAlertsRepository>(
    factory: () => AiAlertsRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<AiAlertsController>(
    factory: () => AiAlertsController(repository: getIt<AiAlertsRepository>()),
  );
}
