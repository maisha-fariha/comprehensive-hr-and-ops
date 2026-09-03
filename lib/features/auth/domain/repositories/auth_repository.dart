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

  Future<Result<void>> refreshTokens({bool silent = false});

  Future<Result<void>> logout();

  Future<Result<void>> registerDevice({
    required String token,
    required String platform,
  });

  bool get hasSession;

  /// Last successful `/mobile/me` payload, used to open a portal offline.
  MobileProfile? get lastKnownProfile;
}
