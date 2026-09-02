import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';

/// Holds the active tenant subdomain for the `X-Tenant-Subdomain` header.
class TenantStore {
  static const _prefsKey = 'tenant_subdomain';

  final SharedPreferences _prefs;
  String? _subdomain;

  TenantStore(this._prefs);

  String? get subdomain => _subdomain;

  Future<void> load() async {
    _subdomain = _prefs.getString(_prefsKey);
    if (_subdomain == null || _subdomain!.isEmpty) {
      final fallback = AppEnv.defaultTenantSubdomain.trim();
      _subdomain = fallback.isEmpty ? null : fallback;
    }
  }

  Future<void> setSubdomain(String? value) async {
    final next = value?.trim();
    _subdomain = (next == null || next.isEmpty) ? null : next;
    if (_subdomain == null) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setString(_prefsKey, _subdomain!);
    }
  }

  Future<void> clear() => setSubdomain(null);
}
