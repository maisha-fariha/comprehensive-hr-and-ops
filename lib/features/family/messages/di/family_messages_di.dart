import 'package:get_it/get_it.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/family_messages_repository_impl.dart';
import '../domain/repositories/family_messages_repository.dart';
import '../presentation/controllers/compose_message_controller.dart';
import '../presentation/controllers/family_messages_controller.dart';

Future<void> setupFamilyMessagesDependencies() async {
  final getIt = GetIt.instance;

  DIHelper.registerRepository<FamilyMessagesRepository>(
    factory: () => FamilyMessagesRepositoryImpl(api: getIt<AppApiClient>()),
  );

  DIHelper.registerController<FamilyMessagesController>(
    factory: () => FamilyMessagesController(
      repository: getIt<FamilyMessagesRepository>(),
    ),
  );

  DIHelper.registerController<ComposeMessageController>(
    factory: () => ComposeMessageController(),
  );
}
