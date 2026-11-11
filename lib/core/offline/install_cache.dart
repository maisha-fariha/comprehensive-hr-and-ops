import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_config.dart';

/// Drops leftover on-device data after a fresh install.
///
/// Preferences are empty on install and are kept across an update, so an
/// update does not clear the session or the saved cache. A reinstall can
/// still find the previous Hive key in the keychain; that leftover is removed
/// only when preferences are empty.
abstract final class InstallCache {
  static const _marker = 'app_install_marker_v1';

  static const _boxes = <String>[
    OfflineConfig.outboxBox,
    OfflineConfig.stagedUploadsBox,
    OfflineConfig.cacheBox,
    '${OfflineConfig.cacheBox}_meta',
    OfflineConfig.legacyCacheBox,
  ];

  static Future<void> clearOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_marker) == true) return;
    // This build is the first to write the marker. Existing preferences mean
    // an update, not a new install.
    if (prefs.getKeys().isNotEmpty) {
      await prefs.setBool(_marker, true);
      return;
    }
    try {
      const secure = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          resetOnError: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      await secure.deleteAll();
    } catch (error) {
      debugPrint('InstallCache: secure storage ($error)');
    }
    try {
      await Hive.initFlutter();
      for (final name in _boxes) {
        try {
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
    } catch (error) {
      debugPrint('InstallCache: boxes ($error)');
    }
    await prefs.setBool(_marker, true);
  }
}
