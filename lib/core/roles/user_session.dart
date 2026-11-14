import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/domain/entities/mobile_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../errors/app_error_dialog.dart';
import '../errors/app_error_mapper.dart';
import '../network/app_api_client.dart';
import '../network/json_codec.dart';
import '../widgets/app_bottom_sheet.dart';
import '../push/device_registration_service.dart';
import '../routing/app_routes.dart';
import '../time/tenant_clock.dart';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyVisibility &&
          dailyLogs == other.dailyLogs &&
          activities == other.activities &&
          incidents == other.incidents &&
          medications == other.medications &&
          documents == other.documents &&
          appointments == other.appointments &&
          messages == other.messages &&
          shiftUpdates == other.shiftUpdates &&
          medicalConditions == other.medicalConditions;

  @override
  int get hashCode => Object.hash(
        dailyLogs,
        activities,
        incidents,
        medications,
        documents,
        appointments,
        messages,
        shiftUpdates,
        medicalConditions,
      );
}

/// App-wide session for the signed-in user's portal role and profile.
///
/// Role is never chosen on the login screen — it comes from `GET /mobile/me`.
class UserSession extends GetxService with WidgetsBindingObserver {
  final Rxn<UserRole> _role = Rxn<UserRole>();
  final RxnString _userId = RxnString();
  final RxString _displayName = ''.obs;
  final RxString _email = ''.obs;
  final RxString _avatarInitials = ''.obs;
  final RxnString _avatarUrl = RxnString();
  final RxnString _residenceId = RxnString();
  final RxnString _residenceName = RxnString();
  final RxnString _organizationName = RxnString();
  final RxnString _organizationLogoUrl = RxnString();
  final RxnString _staffId = RxnString();
  final RxnString _relationship = RxnString();
  final RxnString _selectedClientId = RxnString();
  final RxnString _roleRaw = RxnString();
  final Rxn<StaffKind> _staffKind = Rxn<StaffKind>();
  final RxList<String> _permissions = <String>[].obs;
  final RxBool _permissionsReady = false.obs;
  final RxInt _permissionEpoch = 0.obs;
  /// Web `tenant.modules` from `GET /me` (`/mobile/me` omits this).
  final RxMap<String, bool> _modules = <String, bool>{}.obs;
  final RxBool _modulesKnown = false.obs;
  /// Families stripped after a 403 so nav hides before `/me` catches up.
  final Set<String> _deniedFamilies = <String>{};
  Future<void>? _profileRefresh;
  final RxBool _medAdminCertified = false.obs;
  final RxBool _medAdminApproved = false.obs;
  final Rx<FamilyVisibility> _familyVisibility = FamilyVisibility.unknown.obs;
  bool _signingOut = false;

  UserRole get role => _role.value ?? UserRole.hr;
  bool get isSignedIn => _role.value != null;
  bool get isSigningOut => _signingOut;
  String? get userId => _userId.value;
  RxnString get userIdListenable => _userId;
  String get displayName => _displayName.value;
  String get email => _email.value;
  String get avatarInitials => _avatarInitials.value;
  String? get avatarUrl => _avatarUrl.value;
  String? get residenceId => _residenceId.value;
  String? get residenceName => _residenceName.value;
  String? get organizationName => _organizationName.value;
  /// Settings → General `logoUrl` for web sidebar / header brand.
  String? get organizationLogoUrl => _organizationLogoUrl.value;
  String? get staffId => _staffId.value;
  String? get relationship => _relationship.value;
  String? get selectedClientId => _selectedClientId.value;
  String? get roleRaw => _roleRaw.value;

  /// Assigned role, such as Compliance Officer, rather than the portal name.
  String get roleTitle {
    final raw = (_roleRaw.value ?? '').trim();
    if (raw.isEmpty) return role.label;
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
  StaffKind? get staffKind => _staffKind.value;
  List<String> get permissions => List.unmodifiable(_permissions);

  /// True after `/mobile/me` has applied a permission list, including an
  /// empty one. Until then [can] stays open so the first frame can paint.
  bool get permissionsReady => _permissionsReady.value;
  bool get medAdminCertified => _medAdminCertified.value;
  bool get medAdminApproved => _medAdminApproved.value;
  FamilyVisibility get familyVisibility => _familyVisibility.value;

  String get portalRoute => isSignedIn ? role.portalRoute : AppRoutes.login;

  /// Permission checks follow API keys from `/mobile/me` / `/mobile/home`
  /// (e.g. `clients:read`, `mar:write`). Empty list = first paint before
  /// permissions arrive — keep shell visible.
  /// Bumped on every profile/permission apply — Obx menus must read this
  /// (via [can] / [permissionsReady]) so revoked tabs disappear immediately.
  int get permissionEpoch => _permissionEpoch.value;

  bool get modulesKnown => _modulesKnown.value;

  bool can(String permission) {
    // Touch the epoch so every Obx that checks a permission rebuilds
    // after a refresh, even when the list length stays the same.
    _permissionEpoch.value;
    final needed = _normPerm(permission);
    final family = needed.contains(':') ? needed.split(':').first : needed;
    if (_deniedFamilies.contains(family)) return false;
    // A loaded empty set means the tenant admin revoked everything.
    if (_permissions.isEmpty) return !_permissionsReady.value;
    for (final raw in _permissions) {
      final perm = _normPerm(raw);
      if (perm == needed) return true;
      // `can('clients')` matches `clients:read` / `clients:write`.
      if (!needed.contains(':') && perm.startsWith('$needed:')) return true;
      // `can('mar:write')` also matches bare `mar` if ever returned.
      if (needed.contains(':') && perm == needed.split(':').first) return true;
    }
    return false;
  }

  /// Web `hasModule` — unknown modules stay open until `GET /me` arrives.
  bool hasModule(String? module) {
    _permissionEpoch.value;
    if (module == null || module.isEmpty) return true;
    if (!_modulesKnown.value) return true;
    if (_modules['legacy_unlimited'] == true) return true;
    return _modules[module] == true;
  }

  /// Web nav gate: module enabled (when known) AND any listed permission.
  bool canAccessNav({
    required List<String> anyOf,
    String? module,
  }) {
    if (!hasModule(module)) return false;
    if (anyOf.isEmpty) return true;
    return canAny(anyOf);
  }

  /// Drop a permission family after the API returns 403 so Attendance (etc.)
  /// leaves the bottom nav once `/me` confirms the revoke.
  ///
  /// If the local grant list still includes the family, ignore the 403 for nav
  /// purposes — a stale 403 during pull-to-refresh after an admin re-enable was
  /// sticky-denying Attendance and bouncing the shell to More.
  void noteForbiddenPath(String path) {
    final family = _familyForPath(path);
    if (family == null) return;
    if (_deniedFamilies.contains(family)) return;
    final stillGranted = _permissions.any((p) {
      final n = _normPerm(p);
      return n == family || n.startsWith('$family:');
    });
    // Wait for refreshProfile / `/me` to remove the grant. Hiding immediately
    // from a transient 403 remapped the active tab away on swipe-refresh.
    if (stillGranted) return;
    _deniedFamilies.add(family);
    final next = _permissions
        .where((p) {
          final n = _normPerm(p);
          return n != family && !n.startsWith('$family:');
        })
        .toList();
    if (next.length != _permissions.length) {
      _permissions.assignAll(next);
    }
    _permissionEpoch.value++;
  }

  static String? _familyForPath(String path) {
    final p = path.toLowerCase();
    if (p.contains('/attendance')) return 'attendance';
    if (p.contains('/incidents')) return 'incidents';
    if (p.contains('/shifts') || p.contains('/scheduling')) return 'scheduling';
    if (p.contains('/daily-logs') || p.contains('/daily_logs')) {
      return 'daily-logs';
    }
    if (p.contains('/mar') || p.contains('/medications')) return 'mar';
    if (p.contains('/tasks')) return 'tasks';
    if (p.contains('/handover')) return 'shift-handovers';
    if (p.contains('/emergency')) return 'emergency';
    if (p.contains('/inventory')) return 'inventory';
    if (p.contains('/documents')) return 'documents';
    if (p.contains('/appointments')) return 'appointments';
    if (p.contains('/training')) return 'training';
    if (p.contains('/messaging') || p.contains('/conversations')) {
      return 'messaging';
    }
    if (p.contains('/clients')) return 'clients';
    if (p.contains('/residences')) return 'residences';
    return null;
  }

  static String _normPerm(String value) =>
      value.toLowerCase().replaceAll('_', '-').replaceAll('.', ':');

  /// True when any of [permissions] is granted. Empty means no extra check.
  bool canAny(Iterable<String> permissions) {
    final list = permissions.toList();
    if (list.isEmpty) return true;
    return list.any(can);
  }

  bool get canAccessClients => can('clients');
  bool get canAccessDailyLogs => can('daily-logs');
  bool get canAccessMar => can('mar');
  bool get canWriteMar => can('mar:write');
  bool get canAccessIncidents => can('incidents');
  bool get canAccessTasks => can('tasks');
  bool get canAccessAppointments => can('appointments');
  bool get canWriteAppointments => can('appointments:write');
  bool get canAccessHandovers => can('shift-handovers') || can('handovers');
  bool get canRaiseEmergency => can('emergency:raise');
  bool get canReadEmergency => can('emergency:read') || canRaiseEmergency;

  /// Full staff list (`GET /staff`) — payroll/PII-aware directory.
  bool get canReadStaffList => can('staff:read');

  /// Staff picker / colleagues (`GET /staff/directory` or `/staff` when allowed).
  bool get canUseStaffDirectory =>
      can('staff:directory') || can('staff:read');
  bool get canAccessClientActivities => can('client-activities');
  bool get canWriteClientActivities => can('client-activities:write');
  bool get canAccessMessaging => can('messaging');
  bool get canWriteMessaging => can('messaging:write');
  bool get canMonitorMessaging => can('messaging:monitor');
  bool get canAccessInventory => can('inventory');
  bool get canAccessDocuments => can('documents');
  bool get canWriteDocuments => can('documents:write');
  bool get canAccessTraining => can('training');
  bool get canWriteTraining => can('training:write');
  bool get canAccessAdmissions =>
      can('admissions:read') || can('admissions:write') || can('admissions');

  /// Charting needs `mar:write`. Web does not client-block PRN on cert flags —
  /// the API enforces certification/approval on submit when required.
  bool canAdministerMarDose({required bool isPrn}) => canWriteMar;

  /// Staff Schedule "Upcoming Appointments" follows `appointments:read`.
  bool get canSeeStaffScheduleAppointments => can('appointments:read');

  void applyPermissions(Iterable<String> values) {
    // `/mobile/home` sometimes omits permissions, and a later home payload
    // must not replace the list `/mobile/me` already applied.
    final list = values.toList();
    if (list.isEmpty || _permissionsReady.value) return;
    _permissionsReady.value = true;
    if (_samePermissions(list)) return;
    _permissions.assignAll(list);
    _permissionEpoch.value++;
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
      }
      return;
    }
    if (staffId != null && staffId.isNotEmpty) _staffId.value = staffId;
    if (residenceId != null && residenceId.isNotEmpty) {
      _residenceId.value = residenceId;
    }
    if (residenceName != null && residenceName.isNotEmpty) {
      _residenceName.value = residenceName;
    }
  }

  /// Reloads the access token and `/mobile/me` so a permission the tenant
  /// admin just changed shows up without signing out. Pull-to-refresh and
  /// returning to the app both call this. The web refetches on window focus.
  Future<void> refreshProfile() {
    if (_role.value == null) return Future<void>.value();
    final current = _profileRefresh;
    if (current != null) return current;
    final run = _reloadProfile();
    _profileRefresh = run;
    return run.whenComplete(() {
      if (identical(_profileRefresh, run)) _profileRefresh = null;
    });
  }

  Future<void> _reloadProfile() async {
    try {
      final auth = GetIt.instance<AuthRepository>();
      // Refresh when access is inside the proactive window (~2 min).
      // A 401 from another call still forces a refresh on its own.
      await auth.refreshTokens(silent: true);
      final me = await auth.fetchMe(silent: true);
      final profile = me.value;
      if (profile != null) {
        applyProfile(profile);
      }
      // Web `GET /me` carries `tenant.modules` and a permissions list that
      // `/mobile/me` often omits — required so Attendance leaves the nav when
      // the role or module is revoked (API already returns Missing permission).
      await _reloadWebMe();
      if (profile == null) {
        _permissionEpoch.value++;
      }
    } catch (_) {
      _permissionEpoch.value++;
    }
  }

  /// `GET /me` — same session payload the web shell uses for nav visibility.
  Future<void> _reloadWebMe() async {
    if (!GetIt.instance.isRegistered<AppApiClient>()) return;
    final result =
        await GetIt.instance<AppApiClient>().get('/me', silent: true);
    if (!result.isSuccess) return;
    final body = JsonCodec.unwrapMap(result.value);
    final tenant =
        JsonCodec.mapAt(body, 'tenant') ?? const <String, dynamic>{};
    final rawModules =
        JsonCodec.mapAt(tenant, 'modules') ?? const <String, dynamic>{};
    if (rawModules.isNotEmpty || tenant.containsKey('modules')) {
      _modules
        ..clear()
        ..addAll({
          for (final e in rawModules.entries)
            e.key: JsonCodec.boolean(e.value) ?? false,
        });
      _modulesKnown.value = true;
    }

    final user = JsonCodec.mapAt(body, 'user') ?? body;
    final present = user.containsKey('permissions') ||
        body.containsKey('permissions') ||
        (JsonCodec.mapAt(user, 'role')?.containsKey('permissions') ?? false);
    if (!present) {
      _permissionEpoch.value++;
      return;
    }
    var raw = JsonCodec.listAt(user, 'permissions');
    if (raw.isEmpty) raw = JsonCodec.listAt(body, 'permissions');
    if (raw.isEmpty) {
      final role = JsonCodec.mapAt(user, 'role');
      if (role != null) raw = JsonCodec.listAt(role, 'permissions');
    }
    final list = raw
        .map((item) {
          if (item is Map) {
            final map = JsonCodec.asMap(item);
            return JsonCodec.string(map['key']) ??
                JsonCodec.string(map['name']) ??
                '';
          }
          return JsonCodec.stringOr(item, '');
        })
        .where((item) => item.isNotEmpty)
        .toList();
    // Web `/me` is authoritative after refresh. Clear sticky 403 denials so an
    // admin re-enable (Attendance etc.) is not blocked forever — pull-to-refresh
    // was otherwise remapping the shell to More while can() still failed.
    _reconcileDeniedFamilies(list);
    _permissionsReady.value = true;
    if (!_samePermissions(list)) {
      _permissions.assignAll(list);
    }
    _permissionEpoch.value++;
  }

  void _reconcileDeniedFamilies(List<String> incoming) {
    final families = <String>{};
    for (final p in incoming) {
      final n = _normPerm(p);
      families.add(n.contains(':') ? n.split(':').first : n);
    }
    // Drop denials for families the fresh grant list restores. Revoked
    // modules stay hidden via the grant list alone (no need for sticky 403).
    // Keeping denials while the family was still listed blocked swipe-refresh
    // after re-enable and bounced Attendance → More.
    _deniedFamilies.removeWhere(families.contains);
  }

  void applyProfile(MobileProfile profile) {
    _role.value = profile.role;
    _roleRaw.value = profile.roleRaw.isEmpty ? null : profile.roleRaw;
    _staffKind.value = StaffKind.tryParse(profile.roleRaw);
    _userId.value = profile.id.isEmpty ? null : profile.id;
    _displayName.value = profile.displayName;
    _email.value = profile.email;
    _avatarInitials.value = profile.avatarInitials;
    // `/mobile/me` often omits avatarUrl; keep the photo from `/auth/me`
    // / upload until a non-null URL arrives (same idea as staffId below).
    if (profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty) {
      _avatarUrl.value = profile.avatarUrl;
    }
    _residenceId.value = profile.residenceId;
    _residenceName.value = profile.residenceName;
    // Company / tenant name for portal branding (not the assigned residence).
    _organizationName.value = profile.tenantName ?? profile.residenceName;
    // Logo is filled by Settings → General sync (`applyOrgBranding`).
    // `/mobile/me` often has no staffId. A refresh must not wipe the id
    // `/mobile/home` already stored, or clock-out is sent without it and
    // the API answers "staffId Required" instead of the handover error.
    if (profile.staffId != null && profile.staffId!.isNotEmpty) {
      _staffId.value = profile.staffId;
    }
    _relationship.value = profile.relationship;
    // `/mobile/me` is the authority for grants after login.
    // - permissionsPresent: apply even when empty (revokes remove menu items).
    // - omitted permissions: keep the last known set so a partial payload
    //   cannot wipe the nav.
    if (profile.permissionsPresent) {
      _reconcileDeniedFamilies(profile.permissions);
      _permissionsReady.value = true;
      if (!_samePermissions(profile.permissions)) {
        _permissions.assignAll(profile.permissions);
      }
    } else if (profile.permissions.isNotEmpty) {
      _reconcileDeniedFamilies(profile.permissions);
      _permissionsReady.value = true;
      if (!_samePermissions(profile.permissions)) {
        _permissions.assignAll(profile.permissions);
      }
    } else if (!_permissionsReady.value && _permissions.isNotEmpty) {
      _permissionsReady.value = true;
    }
    _permissionEpoch.value++;
    _medAdminCertified.value = profile.medAdminCertified;
    _medAdminApproved.value = profile.medAdminApproved;
  }

  void applyFamilyHome({
    FamilyVisibility? visibility,
    String? clientId,
    String? residenceName,
  }) {
    // Only notify Obx listeners when values actually change — otherwise every
    // home refresh remounts gated FamilyShell tabs and feels like a redirect.
    if (visibility != null && visibility != _familyVisibility.value) {
      _familyVisibility.value = visibility;
    }
    if (clientId != null &&
        clientId.isNotEmpty &&
        clientId != _selectedClientId.value) {
      _selectedClientId.value = clientId;
    }
    if (residenceName != null &&
        residenceName.isNotEmpty &&
        residenceName != _residenceName.value) {
      _residenceName.value = residenceName;
    }
  }

  void selectClient(String clientId) => _selectedClientId.value = clientId;

  /// Reflects a profile photo change (`PATCH /auth/avatar`) app-wide.
  void updateAvatarUrl(String? url) =>
      _avatarUrl.value = (url == null || url.trim().isEmpty) ? null : url;

  /// Settings → General brand (`platformName`, `logoUrl`) for headers/sidebar.
  void applyOrgBranding({String? name, String? logoUrl}) {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) _organizationName.value = n;
    final logo = logoUrl?.trim();
    _organizationLogoUrl.value = (logo == null || logo.isEmpty) ? null : logo;
  }

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
    // Cold start: re-register the push token if FCM already delivered one.
    try {
      await GetIt.instance<DeviceRegistrationService>().syncAfterAuth();
    } catch (_) {}
    return true;
  }

  /// Clears the local session and returns to the login screen, dropping the
  /// current portal stack so back cannot restore a signed-in shell.
  Future<void> signOut() async {
    _signingOut = true;
    try {
      // Unregister push WHILE the access token still works. Blocking the API
      // first left DELETE /devices unreachable, so alerts kept arriving after
      // logout until the app was uninstalled.
      try {
        await GetIt.instance<DeviceRegistrationService>().unregisterOnLogout();
      } catch (_) {}
      // Block new HTTP so IndexedStack / prewarm cannot keep firing 401s
      // while navigation and controller teardown finish.
      try {
        GetIt.instance<AppApiClient>().noteSessionClosed();
      } catch (_) {}
      // Leave the portal first. If we clear tokens / delete controllers while
      // StaffShell is still mounted, Obx rebuilds recreate controllers and
      // fire unauthenticated GETs → "Sign-in needed" on the login screen.
      if (Get.isDialogOpen == true || AppBottomSheet.isOpen) {
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
    _avatarUrl.value = null;
    _residenceId.value = null;
    _residenceName.value = null;
    _organizationName.value = null;
    _organizationLogoUrl.value = null;
    _staffId.value = null;
    _relationship.value = null;
    _selectedClientId.value = null;
    _roleRaw.value = null;
    _staffKind.value = null;
    _permissions.clear();
    _permissionsReady.value = false;
    _modules.clear();
    _modulesKnown.value = false;
    _deniedFamilies.clear();
    TenantClock.use(null);
    _medAdminCertified.value = false;
    _medAdminApproved.value = false;
    _familyVisibility.value = FamilyVisibility.unknown;
  }

  bool hasRole(UserRole requiredRole) => _role.value == requiredRole;

  bool _applyCachedProfile(AuthRepository auth) {
    final cached = auth.lastKnownProfile;
    if (cached == null) return false;
    applyProfile(cached);
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppErrorDialog.holdTransient();
      refreshProfile();
      // POST /devices again. The server drops a token it could not deliver,
      // and the next message would then never arrive.
      try {
        unawaited(GetIt.instance<DeviceRegistrationService>().syncAfterAuth());
      } catch (_) {}
    }
  }

  bool _samePermissions(List<String> next) {
    if (_permissions.length != next.length) return false;
    final current = _permissions.map(_normPerm).toSet();
    final incoming = next.map(_normPerm).toSet();
    return current.length == incoming.length && current.containsAll(incoming);
  }

  bool _keepSessionOn(AppError? error) {
    if (error == null) return false;
    if (error is AuthError || error is PermissionError) return false;
    if (error is ApiError && error.statusCode == 429) return true;
    if (error.code == 'RATE_LIMITED') return true;
    if (error is ApiError &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return false;
    }
    if (AppErrorMapper.isTransient(error)) return true;
    return AppErrorMapper.from(error).isOffline;
  }
}
