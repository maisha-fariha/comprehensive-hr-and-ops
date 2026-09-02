import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/domain/entities/mobile_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../routing/app_routes.dart';
import 'user_role.dart';

/// App-wide session for the signed-in user's portal role and profile.
///
/// Role is never chosen on the login screen — it comes from `GET /mobile/me`.
class UserSession extends GetxService {
  final Rxn<UserRole> _role = Rxn<UserRole>();
  final RxString _displayName = ''.obs;
  final RxString _email = ''.obs;
  final RxString _avatarInitials = ''.obs;
  final RxnString _residenceId = RxnString();
  final RxnString _residenceName = RxnString();
  final RxnString _organizationName = RxnString();
  final RxnString _staffId = RxnString();
  final RxList<String> _permissions = <String>[].obs;

  UserRole get role => _role.value ?? UserRole.hr;
  bool get isSignedIn => _role.value != null;
  String get displayName => _displayName.value;
  String get email => _email.value;
  String get avatarInitials => _avatarInitials.value;
  String? get residenceId => _residenceId.value;
  String? get residenceName => _residenceName.value;
  String? get organizationName => _organizationName.value;
  String? get staffId => _staffId.value;
  List<String> get permissions => List.unmodifiable(_permissions);

  String get portalRoute => isSignedIn ? role.portalRoute : AppRoutes.login;

  /// When `/mobile/me` (or `/mobile/home`) has not returned permissions yet,
  /// screens stay visible so a first paint does not hide the whole shell.
  bool can(String permission) {
    if (_permissions.isEmpty) return true;
    final needed = permission.toLowerCase();
    for (final raw in _permissions) {
      final perm = raw.toLowerCase();
      if (perm == needed) return true;
      if (perm.startsWith('$needed:')) return true;
      if (needed.contains(':') && perm == needed.split(':').first) return true;
    }
    return false;
  }

  bool get canAccessClients => can('clients');
  bool get canAccessDailyLogs => can('daily-logs') || can('daily_logs');
  bool get canAccessMar => can('mar');
  bool get canAccessIncidents => can('incidents');
  bool get canAccessTasks => can('tasks');
  bool get canAccessAppointments => can('appointments');
  bool get canAccessHandovers => can('shift-handovers') || can('handovers');

  void applyPermissions(Iterable<String> values) {
    if (values.isEmpty) return;
    _permissions.assignAll(values);
  }

  void applyStaffContext({
    String? staffId,
    String? residenceId,
    String? residenceName,
  }) {
    if (staffId != null && staffId.isNotEmpty) _staffId.value = staffId;
    if (residenceId != null && residenceId.isNotEmpty) {
      _residenceId.value = residenceId;
    }
    if (residenceName != null && residenceName.isNotEmpty) {
      _residenceName.value = residenceName;
      _organizationName.value = residenceName;
    }
  }

  void applyProfile(MobileProfile profile) {
    _role.value = profile.role;
    _displayName.value = profile.displayName;
    _email.value = profile.email;
    _avatarInitials.value = profile.avatarInitials;
    _residenceId.value = profile.residenceId;
    _residenceName.value = profile.residenceName;
    _organizationName.value = profile.residenceName ?? profile.tenantName;
    _staffId.value = profile.staffId;
    _permissions.assignAll(profile.permissions);
  }

  /// Rehydrates tokens → `/mobile/me` on cold start. Returns true when a
  /// portal can be opened immediately.
  Future<bool> restore() async {
    final auth = GetIt.instance<AuthRepository>();
    if (!auth.hasSession) return false;

    var me = await auth.fetchMe();
    if (me.isFailure) {
      final refreshed = await auth.refreshTokens();
      if (refreshed.isFailure) {
        await auth.logout();
        return false;
      }
      me = await auth.fetchMe();
    }
    final profile = me.value;
    if (profile == null) {
      await auth.logout();
      return false;
    }
    applyProfile(profile);
    return true;
  }

  /// Clears the local session and returns to the login screen, dropping the
  /// current portal stack so back cannot restore a signed-in shell.
  Future<void> signOut() async {
    try {
      await GetIt.instance<AuthRepository>().logout();
    } catch (_) {}
    _clear();
    Get.offAllNamed(AppRoutes.login);
  }

  void _clear() {
    _role.value = null;
    _displayName.value = '';
    _email.value = '';
    _avatarInitials.value = '';
    _residenceId.value = null;
    _residenceName.value = null;
    _organizationName.value = null;
    _staffId.value = null;
    _permissions.clear();
  }

  bool hasRole(UserRole requiredRole) => _role.value == requiredRole;
}
