import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/app_error_dialog.dart';

/// Thin wrapper around [ScaffoldMessenger] that avoids GetX snackbar races.
///
/// [Get.snackbar] can leave the GetX snackbar queue half-initialized; a later
/// [Get.back] then crashes with `LateInitializationError` on
/// `SnackbarController._controller` while trying to close the snackbar.
abstract final class AppSnackbar {
  static void show(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    if (Get.isDialogOpen == true || AppErrorDialog.recentlyShown) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final trimmedMessage = message.trim();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            position == SnackPosition.TOP ? 72 : 16,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trimmedMessage.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  trimmedMessage,
                  style: const TextStyle(fontFamily: 'Outfit'),
                ),
              ],
            ],
          ),
        ),
      );
  }

  const AppSnackbar._();
}
