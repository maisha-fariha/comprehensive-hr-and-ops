import 'package:get_it/get_it.dart';

import '../config/app_env.dart';
import 'tenant_store.dart';
import 'token_store.dart';

/// Resolves stored-file URLs (e.g. `/api/v1/files/...`) for direct loading,
/// such as `Image.network`, which bypasses [AppApiClient].
abstract final class AuthorizedFile {
  static String resolveUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final origin = base.replaceAll(RegExp(r'/api/v1$'), '');
    if (trimmed.startsWith('/api/')) return '$origin$trimmed';
    if (trimmed.startsWith('/')) return '$base$trimmed';
    return '$base/$trimmed';
  }

  /// Bearer + tenant headers; files under `/files/` return 401 without them.
  static Map<String, String> headers() {
    final headers = <String, String>{};
    final getIt = GetIt.instance;
    if (getIt.isRegistered<TokenStore>()) {
      final token = getIt<TokenStore>().accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    if (getIt.isRegistered<TenantStore>()) {
      final subdomain = getIt<TenantStore>().subdomain;
      if (subdomain != null && subdomain.isNotEmpty) {
        headers['X-Tenant-Subdomain'] = subdomain;
      }
    }
    return headers;
  }

  const AuthorizedFile._();
}
