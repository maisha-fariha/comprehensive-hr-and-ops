import 'package:get/get.dart';

import '../errors/app_error_dialog.dart';

/// Thin wrapper around [Get.snackbar] that avoids racing with
/// [AppErrorDialog] (which already surfaces network/API failures).
///
/// Showing a GetX snackbar while a dialog is open (or just shown) can leave
/// the snackbar queue half-initialized; a later [Get.back] then crashes with
/// `LateInitializationError` on `SnackbarController._controller`.
abstract final class AppSnackbar {
  static void show(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.isDialogOpen == true || AppErrorDialog.recentlyShown) return;
    Get.snackbar(
      title,
      message,
      snackPosition: position,
    );
  }

  const AppSnackbar._();
}
