/// Centralized route name constants. Add new role portals/screens here as
/// they are implemented so navigation stays discoverable from one place.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String hr = '/hr';
  static const String staff = '/staff';
  static const String family = '/family';
  static const String accessDenied = '/access-denied';

  const AppRoutes._();
}
