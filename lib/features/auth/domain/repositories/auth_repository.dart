import 'package:gems_core/gems_core.dart';

import '../entities/mobile_profile.dart';
import '../entities/tenant_info.dart';

abstract class AuthRepository {
  Future<Result<TenantInfo>> lookupTenant(String code);

  Future<Result<MobileProfile>> login({
    required String email,
    required String password,
  });

  Future<Result<MobileProfile>> fetchMe({bool silent = false});

  Future<Result<void>> requestPasswordReset(String email);

  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<Result<void>> requestOtp(String email);

  Future<Result<MobileProfile>> verifyOtp({
    required String email,
    required String code,
  });

  /// Exchanges the refresh token. No-ops while the access token has more
  /// than 60 seconds left, unless [force] is true (a request just returned
  /// 401). Concurrent callers share one in-flight exchange.
  Future<Result<void>> refreshTokens({bool silent = false, bool force = false});

  Future<Result<void>> logout();

  /// POST /devices — register FCM/APNs token after login / token refresh.
  Future<Result<void>> registerDevice({
    required String token,
    required String platform,
    String? appVersion,
  });

  /// DELETE /devices/{token} — call on logout so this device stops receiving
  /// push for the signed-out user.
  Future<Result<void>> unregisterDevice(String token);

  /// GET /devices — devices currently registered for this user.
  Future<Result<List<Map<String, dynamic>>>> listDevices();

  bool get hasSession;

  /// Last successful `/mobile/me` payload, used to open a portal offline.
  MobileProfile? get lastKnownProfile;
}
