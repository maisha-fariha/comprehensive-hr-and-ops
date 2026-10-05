import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../formatting/web_formats.dart';
import '../offline/offline_bootstrap.dart';
import '../offline/offline_outbox.dart';
import '../routing/app_routes.dart';
import 'connectivity_monitor.dart';

/// Compact sync-status strip above every screen. Hidden while online with
/// nothing waiting; otherwise shows offline state, unsent changes, sending
/// progress or items that need attention.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const Color _offline = Color(0xFF5C4A1F);
  static const Color _sending = Color(0xFF0E4A54);
  static const Color _waiting = Color(0xFF16293F);
  static const Color _attention = Color(0xFF8A2C2C);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityMonitor>()) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final online = Get.find<ConnectivityMonitor>().isOnline.value;
      final outbox = OfflineOutbox.maybe;
      outbox?.store.items.length;
      final syncing = outbox?.engine.isSyncing.value ?? false;
      final remaining = outbox?.engine.inFlightRemaining.value ?? 0;
      final pending = outbox?.pendingCount ?? 0;
      final attention = outbox?.attentionCount ?? 0;
      final savedAt = OfflineBootstrap.cache?.lastServedSavedAt.value;

      if (!online) {
        final lines = <String>[
          'You are offline. Showing last saved information.'
              '${savedAt == null ? '' : ' Last updated ${_stamp(savedAt)}.'}',
          if (pending + attention > 0)
            '${_changes(pending + attention)} saved on this device.',
        ];
        return _Strip(
          key: const Key('sync-banner-offline'),
          color: _offline,
          icon: Icons.wifi_off_rounded,
          text: lines.join('\n'),
          onTap: pending + attention > 0 ? _openPending : null,
        );
      }
      if (syncing && remaining > 0) {
        return _Strip(
          key: const Key('sync-banner-sending'),
          color: _sending,
          icon: Icons.cloud_upload_outlined,
          text: 'Sending ${_changes(remaining)}…',
          busy: true,
        );
      }
      if (attention > 0) {
        return _Strip(
          key: const Key('sync-banner-attention'),
          color: _attention,
          icon: Icons.error_outline_rounded,
          text: '${_changes(attention)} need${attention == 1 ? 's' : ''} '
              'attention',
          action: 'Review',
          onTap: _openPending,
        );
      }
      if (pending > 0) {
        return _Strip(
          key: const Key('sync-banner-waiting'),
          color: _waiting,
          icon: Icons.cloud_queue_rounded,
          text: '${_changes(pending)} waiting to send',
          action: 'Review',
          onTap: _openPending,
        );
      }
      return const SizedBox.shrink();
    });
  }

  static String _changes(int n) => n == 1 ? '1 change' : '$n changes';

  static String _stamp(DateTime at) {
    final now = DateTime.now();
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return today ? WebFormat.time(at) : WebFormat.dateTime(at);
  }

  static void _openPending() {
    if (Get.currentRoute == AppRoutes.pendingChanges) return;
    unawaited(Get.toNamed(AppRoutes.pendingChanges));
  }
}

class _Strip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final String? action;
  final bool busy;
  final VoidCallback? onTap;

  const _Strip({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.action,
    this.busy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    action!,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OfflineAwareApp extends StatelessWidget {
  final Widget child;

  const OfflineAwareApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}
