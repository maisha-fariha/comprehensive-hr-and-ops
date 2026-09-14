import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/domain/entities/mobile_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../errors/app_error_mapper.dart';
import '../routing/app_routes.dart';
import 'session_lifecycle.dart';
import 'user_role.dart';

/// Tenant-configured family portal visibility from `GET /family/home`.
class FamilyVisibility {
  final bool dailyLogs;
  final bool activities;
  final bool incidents;
  final bool medications;
  final bool documents;
  final bool appointments;
  final bool messages;
  final bool shiftUpdates;
  final bool medicalConditions;

  const FamilyVisibility({
    this.dailyLogs = true,
    this.activities = true,
    this.incidents = true,
    this.medications = false,
    this.documents = false,
    this.appointments = true,
    this.messages = true,
    this.shiftUpdates = false,
    this.medicalConditions = false,
  });

  static const FamilyVisibility unknown = FamilyVisibility();
}

/// App-wide session for the signed-in user's portal role and profile.
///
/// Role is never chosen on the login screen — it comes from `GET /mobile/me`.
class UserSession extends GetxService {
  final Rxn<UserRole> _role = Rxn<UserRole>();
  final RxnString _userId = RxnString();
  final RxString _displayName = ''.obs;
  final RxString _email = ''.obs;
  final RxString _avatarInitials = ''.obs;
  final RxnString _residenceId = RxnString();
  final RxnString _residenceName = RxnString();
  final RxnString _organizationName = RxnString();
  final RxnString _staffId = RxnString();
  final RxnString _relationship = RxnString();
  final RxnString _selectedClientId = RxnString();
  final RxnString _roleRaw = RxnString();
  final Rxn<StaffKind> _staffKind = Rxn<StaffKind>();
  final RxList<String> _permissions = <String>[].obs;
  final Rx<FamilyVisibility> _familyVisibility = FamilyVisibility.unknown.obs;
  bool _signingOut = false;

  UserRole get role => _role.value ?? UserRole.hr;
  bool get isSignedIn => _role.value != null;
  bool get isSigningOut => _signingOut;
  String? get userId => _userId.value;
  String get displayName => _displayName.value;
  String get email => _email.value;
  String get avatarInitials => _avatarInitials.value;
  String? get residenceId => _residenceId.value;
  String? get residenceName => _residenceName.value;
  String? get organizationName => _organizationName.value;
  String? get staffId => _staffId.value;
  String? get relationship => _relationship.value;
  String? get selectedClientId => _selectedClientId.value;
  String? get roleRaw => _roleRaw.value;
  StaffKind? get staffKind => _staffKind.value;
  List<String> get permissions => List.unmodifiable(_permissions);
  FamilyVisibility get familyVisibility => _familyVisibility.value;

  String get portalRoute => isSignedIn ? role.portalRoute : AppRoutes.login;

  /// Permission checks follow API keys from `/mobile/me` / `/mobile/home`
  /// (e.g. `clients:read`, `mar:write`). Empty list = first paint before
  /// permissions arrive — keep shell visible.
  bool can(String permission) {
    if (_permissions.isEmpty) return true;
    final needed = permission.toLowerCase().replaceAll('_', '-');
    for (final raw in _permissions) {
      final perm = raw.toLowerCase().replaceAll('_', '-');
      if (perm == needed) return true;
      // `can('clients')` matches `clients:read` / `clients:write`.
      if (!needed.contains(':') && perm.startsWith('$needed:')) return true;
      // `can('mar:write')` also matches bare `mar` if ever returned.
      if (needed.contains(':') && perm == needed.split(':').first) return true;
    }
    return false;
  }

  bool get canAccessClients => can('clients');
  bool get canAccessDailyLogs => can('daily-logs');
  bool get canAccessMar => can('mar');
  bool get canWriteMar => can('mar:write');
  bool get canAccessIncidents => can('incidents');
  bool get canAccessTasks => can('tasks');
  bool get canAccessAppointments => can('appointments');
  bool get canAccessHandovers => can('shift-handovers') || can('handovers');

  /// Staff Schedule "Upcoming Appointments" — nurse / caregiver only (B2).
  bool get canSeeStaffScheduleAppointments =>
      staffKind == StaffKind.nurse || staffKind == StaffKind.caregiver;

  void applyPermissions(Iterable<String> values) {
    // `/mobile/home` sometimes omits permissions; keep `/mobile/me` values.
    final list = values.toList();
    if (list.isEmpty) return;
    _permissions.assignAll(list);
  }

  void applyStaffContext({
    String? staffId,
    String? residenceId,
    String? residenceName,
    bool replace = false,
  }) {
    if (replace) {
      _staffId.value =
          (staffId != null && staffId.isNotEmpty) ? staffId : null;
      _residenceId.value =
          (residenceId != null && residenceId.isNotEmpty) ? residenceId : null;
      if (residenceName != null && residenceName.isNotEmpty) {
        _residenceName.value = residenceName;
        _organizationName.value = residenceName;
      }
      return;
    }
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
    _roleRaw.value = profile.roleRaw.isEmpty ? null : profile.roleRaw;
    _staffKind.value = StaffKind.tryParse(profile.roleRaw);
    _userId.value = profile.id.isEmpty ? null : profile.id;
    _displayName.value = profile.displayName;
    _email.value = profile.email;
    _avatarInitials.value = profile.avatarInitials;
    _residenceId.value = profile.residenceId;
    _residenceName.value = profile.residenceName;
    _organizationName.value = profile.residenceName ?? profile.tenantName;
    _staffId.value = profile.staffId;
    _relationship.value = profile.relationship;
    _permissions.assignAll(profile.permissions);
  }

  void applyFamilyHome({
    FamilyVisibility? visibility,
    String? clientId,
    String? residenceName,
  }) {
    if (visibility != null) _familyVisibility.value = visibility;
    if (clientId != null && clientId.isNotEmpty) {
      _selectedClientId.value = clientId;
    }
    if (residenceName != null && residenceName.isNotEmpty) {
      _residenceName.value = residenceName;
      _organizationName.value = residenceName;
    }
  }

  void selectClient(String clientId) => _selectedClientId.value = clientId;

  /// Test/dev helper to open a portal without going through `/mobile/me`.
  void signIn({
    required UserRole role,
    required String displayName,
    String email = '',
    String avatarInitials = 'ME',
  }) {
    _role.value = role;
    _displayName.value = displayName;
    _email.value = email;
    _avatarInitials.value = avatarInitials;
  }

  /// Rehydrates tokens → `/mobile/me` on cold start. Returns true when a
  /// portal can be opened immediately.
  Future<bool> restore() async {
    final auth = GetIt.instance<AuthRepository>();
    if (!auth.hasSession) return false;

    var me = await auth.fetchMe(silent: true);
    if (me.isFailure) {
      final refreshed = await auth.refreshTokens(silent: true);
      if (refreshed.isSuccess) {
        me = await auth.fetchMe(silent: true);
      } else if (_keepSessionOn(me.error) || _keepSessionOn(refreshed.error)) {
        return _applyCachedProfile(auth);
      }
    }
    final profile = me.value;
    if (profile == null) {
      if (_keepSessionOn(me.error)) return _applyCachedProfile(auth);
      await auth.logout();
      return false;
    }
    applyProfile(profile);
    return true;
  }

  /// Clears the local session and returns to the login screen, dropping the
  /// current portal stack so back cannot restore a signed-in shell.
  Future<void> signOut() async {
    _signingOut = true;
    try {
      // Leave the portal first. If we clear tokens / delete controllers while
      // StaffShell is still mounted, Obx rebuilds recreate controllers and
      // fire unauthenticated GETs → "Sign-in needed" on the login screen.
      if (Get.isDialogOpen == true) {
        Get.back<void>();
      }
      Get.offAllNamed(AppRoutes.login);
      await SessionLifecycle.reset();
      try {
        await GetIt.instance<AuthRepository>().logout();
      } catch (_) {}
      _clear();
    } finally {
      _signingOut = false;
    }
  }

  void _clear() {
    _role.value = null;
    _userId.value = null;
    _displayName.value = '';
    _email.value = '';
    _avatarInitials.value = '';
    _residenceId.value = null;
    _residenceName.value = null;
    _organizationName.value = null;
    _staffId.value = null;
    _relationship.value = null;
    _selectedClientId.value = null;
    _roleRaw.value = null;
    _staffKind.value = null;
    _permissions.clear();
    _familyVisibility.value = FamilyVisibility.unknown;
  }

  bool hasRole(UserRole requiredRole) => _role.value == requiredRole;

  bool _applyCachedProfile(AuthRepository auth) {
    final cached = auth.lastKnownProfile;
    if (cached == null) return false;
    applyProfile(cached);
    return true;
  }

  bool _keepSessionOn(AppError? error) {
    if (error == null) return false;
    if (error is AuthError || error is PermissionError) return false;
    if (error is ApiError &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return false;
    }
    return AppErrorMapper.from(error).isOffline;
  }
}
