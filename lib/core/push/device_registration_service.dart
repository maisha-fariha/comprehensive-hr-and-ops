import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../roles/user_session.dart';
import 'firebase_push_bridge.dart';

/// Syncs the local push token with POST/DELETE `/devices`.
///
/// Token source (first available):
/// 1. [PushNotificationService] when registered (FCM/APNs provider)
/// 2. SharedPreferences key `gems_push_token` (same key used by gems push)
///
/// No-ops quietly when no token is available yet — call again after FCM
/// delivers a token via [PushNotificationService.tokenChanges].
class DeviceRegistrationService {
  static const String _prefsTokenKey = 'gems_push_token';
  static const String _prefsRegisteredKey = 'gems_push_registered_token';

  final AuthRepository _auth;
  final SharedPreferences _prefs;

  StreamSubscription<String>? _tokenSub;
  bool _syncing = false;

  /// True only after an authenticated [syncAfterAuth]. Starts false so cold
  /// start / login-screen FCM token events never POST `/devices` with 401.
  /// Cleared again on logout until the next signed-in sync.
  bool _pushEnabled = false;

  DeviceRegistrationService({
    required AuthRepository auth,
    required SharedPreferences prefs,
  })  : _auth = auth,
        _prefs = prefs;

  /// Starts listening for FCM token rotation. Does **not** POST /devices here —
  /// that waits for [syncAfterAuth] after login / [UserSession.restore] so we
  /// never register before an authenticated session exists.
  Future<void> start() async {
    await _ensureTokenListener();
  }

  /// POST /devices after login / session restore / FCM token refresh.
  ///
  /// Requires a signed-in [UserSession], not merely a leftover prefs token
  /// (`hasSession`), so cold start / login screen never 401 on /devices.
  Future<void> syncAfterAuth() async {
    if (_syncing) return;
    if (_isSigningOut) return;
    if (!_isSignedIn) return;
    if (!_auth.hasSession) return;

    _pushEnabled = true;
    await _ensureTokenListener();

    final token = await _resolveToken();
    if (token == null || token.isEmpty) return;

    _syncing = true;
    try {
      final platform = _platformLabel();
      final version = await _appVersion();
      final result = await _auth.registerDevice(
        token: token,
        platform: platform,
        appVersion: version,
      );
      if (result.isSuccess) {
        await _prefs.setString(_prefsRegisteredKey, token);
        await _prefs.setString(_prefsTokenKey, token);
      }
    } finally {
      _syncing = false;
    }
  }

  bool get _isSignedIn {
    try {
      return Get.isRegistered<UserSession>() &&
          Get.find<UserSession>().isSignedIn;
    } catch (_) {
      return false;
    }
  }

  bool get _isSigningOut {
    try {
      return Get.isRegistered<UserSession>() &&
          Get.find<UserSession>().isSigningOut;
    } catch (_) {
      return false;
    }
  }

  /// Stops server + device push delivery for this install.
  ///
  /// 1. DELETE `/devices/{token}` while the access token still works
  /// 2. Delete the FCM registration so the OS stops delivering
  /// 3. Clear tray notifications and local token prefs
  Future<void> unregisterOnLogout() async {
    _pushEnabled = false;
    await _tokenSub?.cancel();
    _tokenSub = null;

    final token = _prefs.getString(_prefsRegisteredKey) ??
        _prefs.getString(_prefsTokenKey) ??
        await _resolveToken();

    if (token != null && token.isNotEmpty) {
      try {
        await _auth.unregisterDevice(token);
      } catch (_) {}
    }

    // Invalidate FCM so background pushes stop without uninstalling.
    // May mint a new token via onTokenRefresh — ignored while !_pushEnabled.
    try {
      final push = _pushService;
      if (push != null) await push.clearToken();
    } catch (_) {}

    try {
      await messageNotifications.cancelAll();
    } catch (_) {}

    await _prefs.remove(_prefsRegisteredKey);
    await _prefs.remove(_prefsTokenKey);
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  Future<void> _ensureTokenListener() async {
    if (_tokenSub != null) return;
    final push = _pushService;
    if (push == null) return;
    _tokenSub = push.tokenChanges.listen((_) {
      if (!_pushEnabled) return;
      unawaited(syncAfterAuth());
    });
  }

  Future<String?> _resolveToken() async {
    final push = _pushService;
    if (push != null) {
      final live = await push.getToken();
      if (live != null && live.isNotEmpty) return live;
      final stored = await push.getStoredToken();
      if (stored != null && stored.isNotEmpty) return stored;
    }
    final fromPrefs = _prefs.getString(_prefsTokenKey);
    if (fromPrefs != null && fromPrefs.isNotEmpty) return fromPrefs;
    return null;
  }

  PushNotificationService? get _pushService {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<PushNotificationService>()) return null;
    return getIt<PushNotificationService>();
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
    } catch (_) {}
    return 'unknown';
  }

  Future<String?> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return null;
    }
  }
}
