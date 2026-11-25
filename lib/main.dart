import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/deeplink/app_deep_link_router.dart';
import 'core/di/service_locator.dart';
import 'core/errors/app_error_dialog.dart';
import 'core/network/connectivity_monitor.dart';
import 'core/offline/install_cache.dart';
import 'core/offline/offline_bootstrap.dart';
import 'core/push/firebase_push_bridge.dart';
import 'core/network/app_api_client.dart';
import 'core/roles/user_session.dart';
import 'core/time/tenant_clock.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before any request. A phone that just powered on has no radio yet, and
  // the first calls must not surface as "Sign-in needed".
  AppErrorDialog.holdTransient();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await Get.put(ConnectivityMonitor(), permanent: true).start();

  await InstallCache.clearOnFreshInstall();
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
  AppErrorDialog.holdTransient();

  // Cold-start App Link while already signed in (attach ran before restore).
  if (session.isSignedIn) {
    try {
      await TenantClock.syncFromApi(
        GetIt.instance<AppApiClient>(),
        force: true,
      );
    } catch (_) {}
    try {
      GetIt.instance<AppDeepLinkRouter>().flushAfterAuth();
    } catch (_) {}
  }

  runApp(const ComprehensiveHrAndOpsApp());
}
