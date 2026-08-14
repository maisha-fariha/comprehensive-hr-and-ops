import 'package:get/get.dart';

import '../routing/app_routes.dart';
import 'user_role.dart';

/// Minimal, app-wide session holder for the signed-in user's active role.
///
/// There is no authentication backend yet — [signIn] is called from the login
/// screen after the user picks an account type. Every role-gated route and
/// widget already reads from here, so wiring real auth later only needs to
/// replace that call site.
class UserSession extends GetxService {
  final Rx<UserRole> _role = UserRole.hr.obs;
  final RxString _displayName = ''.obs;

  UserRole get role => _role.value;
  String get displayName => _displayName.value;

  void signIn({required UserRole role, required String displayName}) {
    _role.value = role;
    _displayName.value = displayName;
  }

  /// Clears the local session and returns to the login screen, dropping the
  /// current portal stack so back cannot restore a signed-in shell.
  void signOut() {
    _displayName.value = '';
    Get.offAllNamed(AppRoutes.login);
  }

  bool hasRole(UserRole requiredRole) => _role.value == requiredRole;
}
