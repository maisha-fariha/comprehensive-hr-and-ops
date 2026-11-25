import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../family_shell.dart';
import 'controllers/family_shell_controller.dart';

/// Switches Family bottom-nav tabs without remounting the portal when possible.
///
/// Prefer this over `Get.offAll(FamilyShell(...))` from Overview / Journal /
/// nested More screens — remounting after pull-to-refresh looked like an
/// auto-redirect when visibility/permissions refreshed.
void familyGoToTab(int index, {BuildContext? context}) {
  final next = index.clamp(0, 4);
  if (Get.isRegistered<FamilyShellController>()) {
    final canPop = context != null
        ? Navigator.of(context).canPop()
        : (Get.key.currentState?.canPop() ?? false);
    if (canPop) {
      Get.until((route) => route.isFirst);
    }
    Get.find<FamilyShellController>().goTo(next);
    return;
  }
  Get.offAll(() => FamilyShell(initialIndex: next));
}
