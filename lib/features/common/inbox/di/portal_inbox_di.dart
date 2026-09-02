import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/portal_inbox_repository_impl.dart';
import '../domain/repositories/portal_inbox_repository.dart';

Future<void> setupPortalInboxDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<PortalInboxRepository>(
    factory: () => PortalInboxRepositoryImpl(api: getIt<AppApiClient>()),
  );
}
