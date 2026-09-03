import 'package:flutter/material.dart';
import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import 'app_error_mapper.dart';

/// Central dialogs for network, auth, and server failures.
/// Debounced so parallel API calls do not stack multiple alerts.
abstract final class AppErrorDialog {
  static DateTime? _lastShownAt;
  static String? _lastKey;
  static const _debounce = Duration(seconds: 4);

  static bool get recentlyShown {
    if (_lastShownAt == null) return false;
    return DateTime.now().difference(_lastShownAt!) < _debounce;
  }

  static Future<void> showError(
    AppError? error, {
    String? fallbackTitle,
    VoidCallback? onRetry,
  }) {
    final info = AppErrorMapper.from(error, fallbackTitle: fallbackTitle);
    return showInfo(
      title: info.title,
      message: info.message,
      isOffline: info.isOffline,
      onRetry: info.canRetry ? onRetry : null,
    );
  }

  /// Client-side validation (empty fields, mismatches). Skips when an API
  /// dialog was just shown so login/forgot/OTP do not double-alert.
  static Future<void> showPageError({
    required String title,
    required String message,
    bool isOffline = false,
  }) {
    if (message.trim().isEmpty) return Future.value();
    if (Get.isDialogOpen == true || recentlyShown) return Future.value();
    return showInfo(title: title, message: message, isOffline: isOffline);
  }

  /// Controllers that still handle [Result.failure] should call this instead
  /// of a snackbar. [AppApiClient] already presents network/server dialogs.
  static Future<void> showResultError(
    AppError? error, {
    String? fallbackTitle,
  }) {
    if (Get.isDialogOpen == true || recentlyShown) return Future.value();
    return showError(error, fallbackTitle: fallbackTitle);
  }

  static Future<void> showInfo({
    required String title,
    required String message,
    bool isOffline = false,
    VoidCallback? onRetry,
  }) async {
    final key = '$title|$message';
    final now = DateTime.now();
    if (_lastKey == key &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _debounce) {
      return;
    }
    _lastKey = key;
    _lastShownAt = now;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    if (Get.isDialogOpen == true) return;

    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Icon(
              isOffline
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              color: isOffline ? AppColors.urgentAmber : AppColors.criticalRed,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: 14.5,
            height: 1.4,
            color: AppColors.textBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text(
              onRetry == null ? 'OK' : 'Close',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Get.back<void>();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Informational (teal) dialog — used when a write is queued offline.
  static Future<void> showQueued(String message) {
    return showInfo(
      title: 'Saved on this device',
      message: message,
      isOffline: true,
    );
  }

  const AppErrorDialog._();
}
