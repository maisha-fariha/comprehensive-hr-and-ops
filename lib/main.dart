import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/di/service_locator.dart';
import 'core/roles/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupAppDependencies(
    apiConfig: const ApiConfig(
      baseUrl: AppEnv.apiBaseUrl,
      enableLogging: AppEnv.enableLogging,
    ),
  );

  final session = Get.put(UserSession(), permanent: true);
  await session.restore();

  runApp(const ComprehensiveHrAndOpsApp());
}
