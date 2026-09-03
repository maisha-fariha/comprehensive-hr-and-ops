import 'dart:convert';

import 'package:gems_core/gems_core.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/app_api_client.dart';
import '../../../../core/network/response_cache.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/network/tenant_store.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/mobile_profile.dart';
import '../../domain/entities/tenant_info.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppApiClient _api;
  final TokenStore _tokens;
  final TenantStore _tenant;
  final ResponseCache? _cache;

  AuthRepositoryImpl({
    required AppApiClient api,
    required TokenStore tokens,
    required TenantStore tenant,
    ResponseCache? cache,
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant,
        _cache = cache;

  @override
  bool get hasSession => _tokens.hasAccessToken;

  @override
  MobileProfile? get lastKnownProfile {
    final raw = _tokens.lastMeJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthMapper.profileFromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<TenantInfo>> lookupTenant(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Enter your workspace code.'),
      );
    }

    final result = await _api.get(
      ApiEndpoints.publicTenant,
      query: {'code': trimmed},
      includeTenant: false,
    );
    return result.when(
      success: (body) async {
        final tenant = AuthMapper.tenantFromJson(body);
        if (tenant.subdomain.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Workspace was not found.'),
          );
        }
        await _tenant.setSubdomain(tenant.subdomain);
        return Result.success(tenant);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MobileProfile>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post(
      ApiEndpoints.mobileLogin,
      data: {'email': email.trim(), 'password': password},
    );
    return result.when(
      success: (body) async {
        final saved = await _saveTokens(body);
        if (saved.isFailure) return Result.failure(saved.error!);
        return fetchMe();
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<MobileProfile>> fetchMe({bool silent = false}) async {
    final result = await _api.get(ApiEndpoints.mobileMe, silent: silent);
    return result.when(
      success: (body) async {
        final profile = AuthMapper.profileFromJson(body);
        if (profile == null) {
          return Result.failure(
            const AuthError(
              message:
                  'This account does not map to a Manager, Staff, or Family portal.',
            ),
          );
        }
        await _tokens.saveLastMe(body);
        if (profile.tenantSubdomain != null &&
            profile.tenantSubdomain!.isNotEmpty) {
          await _tenant.setSubdomain(profile.tenantSubdomain);
        }
        return Result.success(profile);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> requestPasswordReset(String email) {
    return _voidPost(
      ApiEndpoints.mobilePasswordForgot,
      {'email': email.trim()},
    );
  }

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _voidPost(
      ApiEndpoints.mobilePasswordReset,
      {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<Result<void>> requestOtp(String email) {
    return _voidPost(
      ApiEndpoints.mobileOtpRequest,
      {'email': email.trim()},
    );
  }

  @override
  Future<Result<MobileProfile>> verifyOtp({
    required String email,
    required String code,
  }) async {
    final result = await _api.post(
      ApiEndpoints.mobileOtpVerify,
      data: {'email': email.trim(), 'code': code.trim()},
    );
    return result.when(
      success: (body) async {
        final saved = await _saveTokens(body);
        if (saved.isFailure) return Result.failure(saved.error!);
        return fetchMe();
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> refreshTokens({bool silent = false}) async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return Result.failure(
        const AuthError(message: 'No refresh token available.'),
      );
    }
    final result = await _api.post(
      ApiEndpoints.mobileTokenRefresh,
      data: {'refreshToken': refreshToken},
      silent: silent,
    );
    return result.when(
      success: (body) => _saveTokens(body),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> logout() async {
    final refreshToken = _tokens.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _api.post(
        ApiEndpoints.mobileLogout,
        data: {'refreshToken': refreshToken},
        silent: true,
      );
    }
    await _tokens.clear();
    await _cache?.clear();
    return Result.success(null);
  }

  @override
  Future<Result<void>> registerDevice({
    required String token,
    required String platform,
  }) {
    return _voidPost(ApiEndpoints.devices, {
      'token': token,
      'platform': platform,
    });
  }

  Future<Result<void>> _saveTokens(dynamic body) async {
    final AuthTokens? tokens = AuthMapper.tokensFromJson(body);
    if (tokens == null) {
      return Result.failure(
        const ApiError(message: 'Sign-in did not return an access token.'),
      );
    }
    await _tokens.save(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return Result.success(null);
  }

  Future<Result<void>> _voidPost(String path, Map<String, dynamic> data) async {
    final result = await _api.post(path, data: data);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
