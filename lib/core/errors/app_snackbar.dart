import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/app_error_dialog.dart';

/// Thin wrapper around [ScaffoldMessenger] that avoids GetX snackbar races.
///
/// [Get.snackbar] can leave the GetX snackbar queue half-initialized; a later
/// [Get.back] then crashes with `LateInitializationError` on
/// `SnackbarController._controller` while trying to close the snackbar.
abstract final class AppSnackbar {
  static DateTime? _holdUntil;

  /// Keeps the snackbar on screen by skipping non-forced [show] calls for
  /// [duration] (e.g. a feature's "Saved" right after an offline notice).
  static void holdFor(Duration duration) {
    _holdUntil = DateTime.now().add(duration);
  }

  static void show(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    bool force = false,
  }) {
    if (!force &&
        (Get.isDialogOpen == true || AppErrorDialog.recentlyShown)) {
      return;
    }
    final holdUntil = _holdUntil;
    if (!force && holdUntil != null && DateTime.now().isBefore(holdUntil)) {
      return;
    }

    BuildContext? context = Get.overlayContext ?? Get.context;
    ScaffoldMessengerState? messenger =
        context == null ? null : ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      context = Get.key.currentContext;
      if (context != null) {
        messenger = ScaffoldMessenger.maybeOf(context);
      }
    }
    if (messenger == null) return;

    final trimmedMessage = message.trim();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            position == SnackPosition.TOP ? 72 : 16,
            16,
            position == SnackPosition.TOP ? 16 : 16,
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
