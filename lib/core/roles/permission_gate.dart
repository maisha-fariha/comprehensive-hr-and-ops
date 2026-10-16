import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../errors/app_snackbar.dart';
import 'user_session.dart';

/// Builds [builder] only while the signed-in user holds one of [anyOf].
///
/// When a tenant admin revokes the permission, the page is replaced and, if
/// it was pushed, popped. Hiding the menu is not the only check.
class PermissionGate extends StatelessWidget {
  final List<String> anyOf;
  final String title;
  final Widget Function() builder;

  const PermissionGate({
    super.key,
    required this.anyOf,
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_allowed()) return builder();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
      });
      return _PermissionBlocked(title: title);
    });
  }

  bool _allowed() {
    if (anyOf.isEmpty) return true;
    if (!Get.isRegistered<UserSession>()) return true;
    return Get.find<UserSession>().canAny(anyOf);
  }
}

void openPermittedPage({
  required String title,
  required List<String> anyOf,
  required Widget Function() builder,
}) {
  if (Get.isRegistered<UserSession>() &&
      !Get.find<UserSession>().canAny(anyOf)) {
    AppSnackbar.show(
      'Not allowed',
      'You do not have permission to open $title.',
      force: true,
    );
    return;
  }
  Get.to(
    () => PermissionGate(anyOf: anyOf, title: title, builder: builder),
  );
}

/// Manager bottom-nav slots. More (4) is always available.
bool managerTabAllowed(UserSession session, int index) {
  switch (index) {
    case 0:
      return session.can('dashboard:read');
    case 1:
      return session.can('scheduling:read');
    case 2:
      return session.can('attendance:read');
    case 3:
      return session.can('incidents:read');
    default:
      return true;
  }
}

/// Staff bottom-nav slots. Home and More stay so the shell always has a place
/// to land; the home tiles themselves follow permissions.
bool staffTabAllowed(UserSession session, int index) {
  switch (index) {
    case 1:
      return session.can('scheduling:read');
    case 2:
      return session.can('daily-logs:read');
    case 3:
      return session.canAny(const [
        'mar:read',
        'tasks:read',
        'messaging:read',
      ]);
    default:
      return true;
  }
}

int firstAllowedTab({
  required int length,
  required bool Function(int index) allowed,
  int fallback = 0,
}) {
  if (allowed(fallback)) return fallback;
  for (var i = 0; i < length; i++) {
    if (allowed(i)) return i;
  }
  return fallback;
}

class _PermissionBlocked extends StatelessWidget {
  final String title;

  const _PermissionBlocked({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$title is not available for your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
