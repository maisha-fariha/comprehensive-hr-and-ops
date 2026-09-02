import '../../../../core/roles/user_role.dart';

/// Snapshot of `GET /mobile/me` used to pick a portal and seed session UI.
class MobileProfile {
  final String id;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final String roleRaw;
  final List<String> permissions;
  final String? tenantName;
  final String? tenantSubdomain;
  final String? residenceId;
  final String? residenceName;
  final String? staffId;
  final String avatarInitials;

  const MobileProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.roleRaw,
    required this.avatarInitials,
    this.firstName,
    this.lastName,
    this.permissions = const [],
    this.tenantName,
    this.tenantSubdomain,
    this.residenceId,
    this.residenceName,
    this.staffId,
  });
}
