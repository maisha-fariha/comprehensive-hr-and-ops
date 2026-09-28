import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/residences_repository_impl.dart';
import '../domain/repositories/residences_repository.dart';
import '../presentation/controllers/residences_controller.dart';

Future<void> setupHrResidencesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<ResidencesRepository>(
    factory: () => ResidencesRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<ResidencesController>(
    factory: () => ResidencesController(
      repository: getIt<ResidencesRepository>(),
    ),
  );
}
