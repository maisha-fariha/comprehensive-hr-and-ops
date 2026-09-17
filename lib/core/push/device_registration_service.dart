import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';

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

  DeviceRegistrationService({
    required AuthRepository auth,
    required SharedPreferences prefs,
  })  : _auth = auth,
        _prefs = prefs;

  /// Starts listening for token refresh and registers the current token if
  /// the user already has a session.
  Future<void> start() async {
    await _tokenSub?.cancel();
    final push = _pushService;
    if (push != null) {
      _tokenSub = push.tokenChanges.listen((_) {
        unawaited(syncAfterAuth());
      });
    }
    if (_auth.hasSession) {
      await syncAfterAuth();
    }
  }

  /// POST /devices after login / session restore / FCM token refresh.
  Future<void> syncAfterAuth() async {
    if (!_auth.hasSession || _syncing) return;
    final token = await _resolveToken();
    if (token == null || token.isEmpty) return;

    final already = _prefs.getString(_prefsRegisteredKey);
    if (already == token) return;

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

  /// DELETE /devices/{token} before clearing auth on logout.
  Future<void> unregisterOnLogout() async {
    final token = _prefs.getString(_prefsRegisteredKey) ??
        _prefs.getString(_prefsTokenKey) ??
        await _resolveToken();
    if (token == null || token.isEmpty) {
      await _prefs.remove(_prefsRegisteredKey);
      return;
    }
    try {
      await _auth.unregisterDevice(token);
    } catch (_) {}
    await _prefs.remove(_prefsRegisteredKey);
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
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
