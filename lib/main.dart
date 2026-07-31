import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/roles/user_role.dart';
import 'core/roles/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App-wide session. There is no authentication flow yet, so this seeds a
  // single HR/Manager session - swap this call for the real sign-in result
  // once auth is implemented; every role-gated route already reads from
  // `UserSession`, so no other code needs to change.
  Get.put(UserSession(), permanent: true).signIn(
    role: UserRole.hr,
    displayName: 'Alex',
  );

  // Registers every feature module's repository/controller in `get_it`.
  await setupAppDependencies();

  runApp(const ComprehensiveHrAndOpsApp());
}
