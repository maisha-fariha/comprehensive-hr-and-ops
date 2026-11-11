import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_config.dart';

/// Drops leftover on-device data after a fresh install / reinstall.
///
/// Android Auto Backup can restore SharedPreferences after uninstall. That
/// leaves expired tokens, so the app looks signed in and then hits token
/// refresh limits. [PackageInfo.installTime] changes on reinstall even when
/// prefs are restored; updates keep the same install time, so the session
/// stays.
abstract final class InstallCache {
  static const _installTimeKey = 'app_install_time_ms_v1';

  /// Auth / tenant keys that must not survive a reinstall via backup.
  static const _sessionKeys = <String>[
    'mobile_access_token',
    'mobile_refresh_token',
    'mobile_access_expires_at_ms',
    'mobile_last_me',
    'tenant_subdomain',
    'gems_push_token',
    'gems_push_registered_token',
  ];

  static const _boxes = <String>[
    OfflineConfig.outboxBox,
    OfflineConfig.stagedUploadsBox,
    OfflineConfig.cacheBox,
    '${OfflineConfig.cacheBox}_meta',
    OfflineConfig.legacyCacheBox,
  ];

  static Future<void> clearOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? installTime;
    try {
      installTime = (await PackageInfo.fromPlatform()).installTime;
    } catch (error) {
      debugPrint('InstallCache: package info ($error)');
    }

    final currentMs = installTime?.millisecondsSinceEpoch;
    final storedMs = prefs.getInt(_installTimeKey);

    // Same install (including an app update): leave data alone.
    if (currentMs != null && storedMs == currentMs) return;

    final restoredAfterReinstall =
        currentMs != null && storedMs != null && storedMs != currentMs;
    final trueFirstInstall = prefs.getKeys().isEmpty;

    if (restoredAfterReinstall || trueFirstInstall) {
      await _wipeSession(prefs);
      await _wipeSecure();
      await _wipeBoxes();
    }

    // First launch of a build that tracks install time on an existing
    // install: record the stamp only — do not clear the signed-in session.
    if (currentMs != null) {
      await prefs.setInt(_installTimeKey, currentMs);
    } else if (storedMs == null) {
      await prefs.setInt(
        _installTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  static Future<void> _wipeSession(SharedPreferences prefs) async {
    for (final key in _sessionKeys) {
      try {
        await prefs.remove(key);
      } catch (_) {}
    }
  }

  static Future<void> _wipeSecure() async {
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
  }

  static Future<void> _wipeBoxes() async {
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
  }
}
