import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/visit_requests_repository_impl.dart';
import '../domain/repositories/visit_requests_repository.dart';
import '../presentation/controllers/family_visit_requests_controller.dart';
import '../presentation/controllers/visit_request_details_controller.dart';

Future<void> setupFamilyVisitRequestsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<VisitRequestsRepository>(
    factory: () => VisitRequestsRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<FamilyVisitRequestsController>(
    factory: () => FamilyVisitRequestsController(
      repository: getIt<VisitRequestsRepository>(),
    ),
  );

  DIHelper.registerController<VisitRequestDetailsController>(
    factory: () => VisitRequestDetailsController(
      repository: getIt<VisitRequestsRepository>(),
    ),
  );
}
