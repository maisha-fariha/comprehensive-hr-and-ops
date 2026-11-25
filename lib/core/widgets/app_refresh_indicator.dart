import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../roles/user_session.dart';

/// Pull-to-refresh that also reloads `/mobile/me`.
///
/// Page data and permission-gated controls (New Task, menus, write actions)
/// then match a role change without signing out.
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final Color? color;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  Future<void> _refresh() async {
    if (Get.isRegistered<UserSession>()) {
      await Get.find<UserSession>().refreshProfile();
    }
    await onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color,
      onRefresh: _refresh,
      child: child,
    );
  }
}
