import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../features/hr/hr_shell.dart';
import '../../features/hr/scheduling/presentation/pages/create_shift_page.dart';
import '../../features/staff/staff_shell.dart';
import '../network/tenant_store.dart';
import '../roles/user_role.dart';
import '../roles/user_session.dart';
import 'scheduling_deep_link.dart';

/// Opens Schedule / Edit Shift from HTTPS App Links and `hrcare://shifts/...`.
///
/// Email example:
/// `https://my-care.encoderittest.store/dashboard/scheduling?shiftId=…&action=edit`
class AppDeepLinkRouter {
  final AppLinks _links;
  StreamSubscription<Uri>? _sub;
  SchedulingDeepLink? _pending;
  bool _opening = false;

  AppDeepLinkRouter({AppLinks? links}) : _links = links ?? AppLinks();

  Future<void> attach() async {
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) _queue(initial);
    } catch (_) {}
    _sub ??= _links.uriLinkStream.listen(
      _queue,
      onError: (_) {},
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Call after a successful sign-in so a cold-start link can finish.
  void flushAfterAuth() => _flush();

  void _queue(Uri uri) {
    final parsed = SchedulingDeepLink.tryParse(uri);
    if (parsed == null) return;
    _pending = parsed;
    _flush();
  }

  void _flush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pending == null || _opening) return;
      if (!_navigatorReady()) {
        _flush();
        return;
      }
      if (!Get.isRegistered<UserSession>() ||
          !Get.find<UserSession>().isSignedIn) {
        // Keep pending until login completes.
        return;
      }
      final link = _pending!;
      _pending = null;
      unawaited(_open(link));
    });
  }

  bool _navigatorReady() {
    try {
      return Get.key.currentState != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _open(SchedulingDeepLink link) async {
    _opening = true;
    try {
      final tenant = link.tenantSubdomain?.trim();
      if (tenant != null &&
          tenant.isNotEmpty &&
          GetIt.instance.isRegistered<TenantStore>()) {
        final store = GetIt.instance<TenantStore>();
        if (store.subdomain != tenant) {
          await store.setSubdomain(tenant);
        }
      }

      final session = Get.find<UserSession>();
      final shiftId = link.shiftId;
      if (shiftId.isEmpty) return;

      switch (session.role) {
        case UserRole.hr:
          Get.offAll(
            () => HrShell(
              initialIndex: 1,
              scheduleFocusShiftId: shiftId,
            ),
          );
          if (link.action == 'edit' || link.action.isEmpty) {
            await Future<void>.delayed(const Duration(milliseconds: 80));
            await Get.to(() => CreateShiftPage(editShiftId: shiftId));
          }
        case UserRole.staff:
          Get.offAll(
            () => StaffShell(
              initialIndex: 1,
              scheduleFocusShiftId: shiftId,
            ),
          );
        case UserRole.family:
          break;
      }
    } finally {
      _opening = false;
    }
  }
}
