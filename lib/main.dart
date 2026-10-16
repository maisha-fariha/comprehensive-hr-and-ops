import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/di/service_locator.dart';
import 'core/network/connectivity_monitor.dart';
import 'core/offline/offline_bootstrap.dart';
import 'core/roles/user_session.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await Get.put(ConnectivityMonitor(), permanent: true).start();

  await OfflineBootstrap.openStorage();

  await setupAppDependencies(
    apiConfig: const ApiConfig(
      baseUrl: AppEnv.apiBaseUrl,
      enableLogging: AppEnv.enableLogging,
    ),
  );

  await OfflineBootstrap.attach();

  final session = Get.put(UserSession(), permanent: true);
  OfflineBootstrap.watchSession(session);
  await session.restore();

  runApp(const ComprehensiveHrAndOpsApp());
}
