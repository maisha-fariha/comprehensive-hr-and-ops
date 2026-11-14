import 'dart:convert';

import '../../../../core/network/json_codec.dart';
import '../../../../core/roles/user_role.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/mobile_profile.dart';
import '../../domain/entities/tenant_info.dart';

abstract final class AuthMapper {
  static TenantInfo tenantFromJson(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final nested = JsonCodec.mapAt(json, 'tenant') ?? json;
    final subdomain = JsonCodec.string(nested['subdomain']) ??
        JsonCodec.string(nested['code']) ??
        JsonCodec.string(json['subdomain']) ??
        JsonCodec.string(json['code']) ??
        '';
    return TenantInfo(
      subdomain: subdomain,
      name: JsonCodec.string(nested['name']) ?? JsonCodec.string(json['name']),
      id: JsonCodec.string(nested['id']) ?? JsonCodec.string(json['id']),
    );
  }

  static AuthTokens? tokensFromJson(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final nested = JsonCodec.mapAt(json, 'tokens') ??
        JsonCodec.mapAt(json, 'token') ??
        json;
    final access = JsonCodec.string(nested['accessToken']) ??
        JsonCodec.string(nested['access_token']) ??
        JsonCodec.string(nested['token']) ??
        JsonCodec.string(json['accessToken']) ??
        JsonCodec.string(json['access_token']);
    if (access == null || access.isEmpty) return null;
    return AuthTokens(
      accessToken: access,
      refreshToken: JsonCodec.string(nested['refreshToken']) ??
          JsonCodec.string(nested['refresh_token']) ??
          JsonCodec.string(json['refreshToken']) ??
          JsonCodec.string(json['refresh_token']),
      accessExpiresAt: accessExpiry(
        expiresInSeconds: JsonCodec.integer(
          nested['expiresIn'] ??
              nested['expires_in'] ??
              json['expiresIn'] ??
              json['expires_in'],
        ),
        accessToken: access,
      ),
    );
  }

  /// `expiresIn` is seconds (server sends 900). Never treat it as minutes.
  static DateTime? accessExpiry({
    required int? expiresInSeconds,
    required String accessToken,
  }) {
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      return DateTime.now().add(Duration(seconds: expiresInSeconds));
    }
    return jwtExpiry(accessToken);
  }

  static DateTime? jwtExpiry(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map) return null;
      final exp = JsonCodec.integer(payload['exp']);
      if (exp == null || exp <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
          .toLocal();
    } catch (_) {
      return null;
    }
  }

  static MobileProfile? profileFromJson(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final user = JsonCodec.mapAt(json, 'user') ??
        JsonCodec.mapAt(json, 'profile') ??
        json;

    final roleRaw = _roleRaw(user) ?? _roleRaw(json) ?? '';
    final role = UserRole.tryParse(roleRaw);
    if (role == null) return null;

    final firstName = JsonCodec.string(user['firstName']) ??
        JsonCodec.string(user['first_name']);
    final lastName = JsonCodec.string(user['lastName']) ??
        JsonCodec.string(user['last_name']);
    final email = JsonCodec.stringOr(user['email'] ?? json['email'], '');
    final displayName = JsonCodec.string(user['displayName']) ??
        JsonCodec.string(user['fullName']) ??
        JsonCodec.string(user['name']) ??
        _joinName(firstName, lastName) ??
        (email.contains('@') ? email.split('@').first : 'there');

    final tenant = JsonCodec.mapAt(user, 'tenant') ??
        JsonCodec.mapAt(json, 'tenant');
    final residence = _firstResidence(user) ?? _firstResidence(json);
    final staff = JsonCodec.mapAt(user, 'staff') ??
        JsonCodec.mapAt(json, 'staff');

    return MobileProfile(
      id: JsonCodec.stringOr(user['id'] ?? user['userId'] ?? json['id'], ''),
      email: email,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      role: role,
      roleRaw: roleRaw,
      permissions: _permissions(user, json),
      permissionsPresent: _permissionsPresent(user, json),
      tenantName: JsonCodec.string(tenant?['name']) ??
          JsonCodec.string(user['tenantName']) ??
          JsonCodec.string(json['organizationName']),
      tenantSubdomain: JsonCodec.string(tenant?['subdomain']) ??
          JsonCodec.string(user['tenantSubdomain']),
      residenceId: JsonCodec.string(residence?['id']) ??
          JsonCodec.string(user['residenceId']) ??
          JsonCodec.string(user['currentResidenceId']) ??
          JsonCodec.string(json['residenceId']),
      residenceName: JsonCodec.string(residence?['name']) ??
          JsonCodec.string(user['residenceName']),
      staffId: JsonCodec.string(user['staffId']) ??
          JsonCodec.string(json['staffId']) ??
          JsonCodec.string(staff?['id']),
      relationship: JsonCodec.string(user['relationship']) ??
          JsonCodec.string(json['relationship']) ??
          JsonCodec.string(user['relation']),
      avatarInitials: _initials(displayName, email),
      avatarUrl: JsonCodec.string(
        user['avatarUrl'] ??
            user['avatar'] ??
            user['photoUrl'] ??
            user['profileImageUrl'] ??
            json['avatarUrl'] ??
            staff?['photoUrl'] ??
            staff?['avatarUrl'],
      ),
      medAdminCertified: JsonCodec.boolean(
            user['medAdminCertified'] ??
                json['medAdminCertified'] ??
                staff?['medAdminCertified'],
          ) ??
          false,
      medAdminApproved: JsonCodec.boolean(
            user['medAdminApproved'] ??
                json['medAdminApproved'] ??
                staff?['medAdminApproved'],
          ) ??
          false,
    );
  }

  static const restrictedAccountMessage =
      'This app is for managers, staff and family members. Tenant admin and '
      'platform admin accounts cannot sign in here — please use the web '
      'dashboard.';

  /// Web-only roles: tenant admins and platform operators use the dashboard,
  /// not the mobile portals (Bug Report 001 — Tenant Admin mobile login).
  /// `hr_admin` / residence managers still use the manager shell.
  static const _webOnlyRoles = {
    'tenant_admin',
    'platform_admin',
    'super_admin',
  };

  /// Tenant admin and platform users only have the web dashboard.
  static bool isWebOnlyAccount(dynamic body) {
    final json = JsonCodec.unwrapMap(body);
    final user = JsonCodec.mapAt(json, 'user') ??
        JsonCodec.mapAt(json, 'profile') ??
        json;
    final realm = JsonCodec.string(user['realm']) ?? JsonCodec.string(json['realm']);
    if (realm?.toLowerCase() == 'platform') return true;
    final roles = [
      ...JsonCodec.listAt(user, 'roles'),
      if (!identical(user, json)) ...JsonCodec.listAt(json, 'roles'),
      _roleRaw(user),
    ];
    return roles.any((role) {
      final raw = role is Map
          ? JsonCodec.string(JsonCodec.asMap(role)['key']) ??
              JsonCodec.string(JsonCodec.asMap(role)['name'])
          : JsonCodec.string(role);
      if (raw == null) return false;
      final normalized =
          raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
      return _webOnlyRoles.contains(normalized);
    });
  }

  static String? _roleRaw(Map<String, dynamic> json) {
    final roleValue = json['role'];
    if (roleValue is Map) {
      final roleObj = JsonCodec.asMap(roleValue);
      return JsonCodec.string(roleObj['key']) ??
          JsonCodec.string(roleObj['name']) ??
          JsonCodec.string(roleObj['slug']) ??
          JsonCodec.string(roleObj['code']);
    }

    final direct = JsonCodec.string(roleValue) ??
        JsonCodec.string(json['roleName']) ??
        JsonCodec.string(json['roleKey']) ??
        JsonCodec.string(json['userType']) ??
        JsonCodec.string(json['accountType']) ??
        JsonCodec.string(json['type']);
    if (direct != null) return direct;

    final roles = JsonCodec.listAt(json, 'roles');
    if (roles.isNotEmpty) {
      final first = roles.first;
      if (first is Map) {
        final map = JsonCodec.asMap(first);
        return JsonCodec.string(map['key']) ??
            JsonCodec.string(map['name']) ??
            JsonCodec.string(map['slug']);
      }
      return JsonCodec.string(first);
    }
    return null;
  }

  static bool _permissionsPresent(
    Map<String, dynamic> user,
    Map<String, dynamic> json,
  ) {
    if (user.containsKey('permissions') || json.containsKey('permissions')) {
      return true;
    }
    final role = JsonCodec.mapAt(user, 'role') ?? JsonCodec.mapAt(json, 'role');
    return role != null && role.containsKey('permissions');
  }

  static List<String> _permissions(
    Map<String, dynamic> user,
    Map<String, dynamic> json,
  ) {
    var raw = JsonCodec.listAt(user, 'permissions');
    if (raw.isEmpty) raw = JsonCodec.listAt(json, 'permissions');
    if (raw.isEmpty) {
      final role =
          JsonCodec.mapAt(user, 'role') ?? JsonCodec.mapAt(json, 'role');
      if (role != null) raw = JsonCodec.listAt(role, 'permissions');
    }
    return raw
        .map((item) {
          if (item is Map) {
            final map = JsonCodec.asMap(item);
            return JsonCodec.string(map['key']) ??
                JsonCodec.string(map['name']) ??
                '';
          }
          return JsonCodec.stringOr(item, '');
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic>? _firstResidence(Map<String, dynamic> json) {
    final current = JsonCodec.mapAt(json, 'residence') ??
        JsonCodec.mapAt(json, 'currentResidence');
    if (current != null) return current;
    final list = JsonCodec.listAt(json, 'residences');
    if (list.isEmpty) return null;
    final first = list.first;
    if (first is Map) return JsonCodec.asMap(first);
    return null;
  }

  static String? _joinName(String? first, String? last) {
    final parts = [first, last].whereType<String>().where((p) => p.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String _initials(String displayName, String email) {
    final source = displayName.trim().isEmpty ? email : displayName;
    final parts = source
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ME';
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  const AuthMapper._();
}
