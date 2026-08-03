import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/family/family_shell.dart';
import '../../features/hr/hr_shell.dart';
import '../../features/staff/staff_shell.dart';
import '../roles/user_role.dart';
import 'access_denied_page.dart';
import 'app_routes.dart';
import 'role_guard_middleware.dart';

/// GetX page registry. Each role portal is a single root page whose shell
/// owns its own bottom navigation.
abstract final class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.hr,
      page: () => const HrShell(),
      middlewares: [RoleGuardMiddleware(UserRole.hr)],
    ),
    GetPage(
      name: AppRoutes.staff,
      page: () => const StaffShell(),
      middlewares: [RoleGuardMiddleware(UserRole.staff)],
    ),
    GetPage(
      name: AppRoutes.family,
      page: () => const FamilyShell(),
      middlewares: [RoleGuardMiddleware(UserRole.family)],
    ),
    GetPage(
      name: AppRoutes.accessDenied,
      page: () => const AccessDeniedPage(),
    ),
  ];

  const AppPages._();
}
