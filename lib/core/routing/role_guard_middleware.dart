import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../roles/user_role.dart';
import '../roles/user_session.dart';
import 'app_routes.dart';

/// Restricts a `GetPage` to a single [UserRole]. Attach via
/// `GetPage(middlewares: [RoleGuardMiddleware(UserRole.hr)])` so every
/// role's screens stay isolated from one another as more portals are added.
class RoleGuardMiddleware extends GetMiddleware {
  final UserRole requiredRole;

  RoleGuardMiddleware(this.requiredRole);

  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<UserSession>();
    if (!session.isSignedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (session.hasRole(requiredRole)) return null;
    return const RouteSettings(name: AppRoutes.accessDenied);
  }
}
