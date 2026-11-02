import 'package:gems_core/gems_core.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/app_api_client.dart';
import '../data/repositories/ai_assist_repository_impl.dart';
import '../domain/repositories/ai_assist_repository.dart';

Future<void> setupHrAiAssistDependencies() async {
  final getIt = GetIt.instance;
  DIHelper.registerRepository<AiAssistRepository>(
    factory: () => AiAssistRepositoryImpl(api: getIt<AppApiClient>()),
  );
}
