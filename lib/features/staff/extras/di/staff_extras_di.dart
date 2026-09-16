import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../../../../core/roles/user_session.dart';
import '../data/repositories/staff_extras_repository_impl.dart';
import '../domain/repositories/staff_extras_repository.dart';

Future<void> setupStaffExtrasDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<StaffExtrasRepository>(
    factory: () => StaffExtrasRepositoryImpl(
      api: getIt<AppApiClient>(),
      session: Get.find<UserSession>(),
    ),
  );
}
