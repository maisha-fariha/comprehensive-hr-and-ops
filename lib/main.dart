import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/roles/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App-wide session. Role is set when the user signs in from [LoginPage].
  Get.put(UserSession(), permanent: true);

  // Registers every feature module's repository/controller in `get_it`.
  await setupAppDependencies();

  runApp(const ComprehensiveHrAndOpsApp());
}
