import 'package:get/get.dart';

import 'user_role.dart';

/// Minimal, app-wide session holder for the signed-in user's active role.
///
/// There is no authentication backend yet, so this currently seeds a single
/// HR/Manager session. Once real authentication is wired up, replace
/// [signIn]'s call site (see `main.dart`) with the actual login flow output
/// - every role-gated route and widget already reads from here, so no other
/// call site needs to change.
class UserSession extends GetxService {
  final Rx<UserRole> _role = UserRole.hr.obs;
  final RxString _displayName = 'Alex'.obs;

  UserRole get role => _role.value;
  String get displayName => _displayName.value;

  void signIn({required UserRole role, required String displayName}) {
    _role.value = role;
    _displayName.value = displayName;
  }

  bool hasRole(UserRole requiredRole) => _role.value == requiredRole;
}
