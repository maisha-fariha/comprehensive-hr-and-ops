import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/admissions_repository_impl.dart';
import '../domain/repositories/admissions_repository.dart';
import '../presentation/controllers/admissions_controller.dart';

Future<void> setupHrAdmissionsDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<AdmissionsRepository>(
    factory: () => AdmissionsRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<AdmissionsController>(
    factory: () => AdmissionsController(
      repository: getIt<AdmissionsRepository>(),
      session: Get.find<UserSession>(),
    ),
  );
}
