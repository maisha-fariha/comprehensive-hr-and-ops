/// Compile-time environment for the mobile API.
///
/// Override at build/run time:
/// ```
/// flutter run --dart-define=API_BASE_URL=https://app-hr.encoderittest.store/api/v1
/// flutter run --dart-define=TENANT_SUBDOMAIN=sunrise
/// ```
abstract final class AppEnv {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app-hr.encoderittest.store/api/v1',
  );

  /// Optional workspace/tenant code prefilled on the login screen.
  static const String defaultTenantSubdomain = String.fromEnvironment(
    'TENANT_SUBDOMAIN',
    defaultValue: '',
  );

  static const bool enableLogging = bool.fromEnvironment(
    'API_LOGGING',
    defaultValue: true,
  );

  const AppEnv._();
}
