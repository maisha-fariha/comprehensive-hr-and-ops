import 'package:get/get.dart';

import '../../features/hr/hr_shell.dart';
import '../roles/user_role.dart';
import 'access_denied_page.dart';
import 'app_routes.dart';
import 'role_guard_middleware.dart';

/// GetX page registry. Each role portal is a single root page whose shell
/// owns its own bottom navigation; new portals (Staff, Family) plug in the
/// same way once their Figma screens are implemented.
abstract final class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.hr,
      page: () => const HrShell(),
      middlewares: [RoleGuardMiddleware(UserRole.hr)],
    ),
    GetPage(
      name: AppRoutes.accessDenied,
      page: () => const AccessDeniedPage(),
    ),
  ];

  const AppPages._();
}
