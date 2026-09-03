import 'dart:convert';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists mobile access/refresh tokens and keeps [ApiService] in sync.
class TokenStore {
  static const _accessKey = 'mobile_access_token';
  static const _refreshKey = 'mobile_refresh_token';
  static const _lastMeKey = 'mobile_last_me';

  final SharedPreferences _prefs;
  final ApiService _api;

  TokenStore(this._prefs, this._api);

  String? get accessToken => _prefs.getString(_accessKey);
  String? get refreshToken => _prefs.getString(_refreshKey);
  bool get hasAccessToken => (accessToken ?? '').isNotEmpty;

  void applyToClient() {
    final token = accessToken;
    _api.setAuthToken((token == null || token.isEmpty) ? null : token);
  }

  Future<void> save({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _prefs.setString(_accessKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_refreshKey, refreshToken);
    }
    _api.setAuthToken(accessToken);
  }

  String? get lastMeJson => _prefs.getString(_lastMeKey);

  Future<void> saveLastMe(dynamic body) async {
    try {
      await _prefs.setString(_lastMeKey, jsonEncode(body));
    } catch (_) {}
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
    await _prefs.remove(_lastMeKey);
    _api.setAuthToken(null);
  }
}
