import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../roles/user_session.dart';
import '../offline_outbox.dart';

/// Signs out, first warning when this user still has unsent changes.
/// Unsent changes are kept on the device and sent the next time the same
/// person signs in; they are never replayed for someone else.
abstract final class SignOutGuard {
  static Future<void> signOut() async {
    if (!await confirm()) return;
    await Get.find<UserSession>().signOut();
  }

  /// True when it is OK to sign out.
  static Future<bool> confirm() async {
    final outbox = OfflineOutbox.maybe;
    final count = outbox?.unsentCount ?? 0;
    if (count == 0) return true;
    final result = await Get.dialog<bool>(
      Builder(builder: (ctx) => AlertDialog(
        key: const Key('sign-out-unsent-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          count == 1
              ? '1 change not yet sent'
              : '$count changes not yet sent',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textHeading,
          ),
        ),
        content: const Text(
          'Sign out anyway? They stay saved on this device and will be sent '
          'the next time you sign in.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.5,
            height: 1.4,
            color: AppColors.textBody,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('sign-out-unsent-stay'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay signed in'),
          ),
          TextButton(
            key: const Key('sign-out-unsent-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.criticalRed),
            child: const Text('Sign out anyway'),
          ),
        ],
      )),
    );
    return result == true;
  }
}
