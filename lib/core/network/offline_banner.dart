import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'connectivity_monitor.dart';

/// Compact strip shown while the device has no network.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityMonitor>()) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final online = Get.find<ConnectivityMonitor>().isOnline.value;
      if (online) return const SizedBox.shrink();
      return Material(
        color: const Color(0xFF5C4A1F),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are offline. Showing last saved information.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
