import '../routing/app_routes.dart';

/// The three portals of the Comprehensive HR & Operations Platform, matching
/// the "Manager / HR", "Staff" and "Family" sections of the Figma file.
///
/// Every top-level feature module lives under `lib/features/<role>/...` and
/// is gated behind this enum so role-based navigation/permissions stay
/// centralized and easy to extend as more screens are implemented.
enum UserRole {
  hr('HR / Manager'),
  staff('Staff'),
  family('Family');

  final String label;

  const UserRole(this.label);

  String get portalRoute {
    switch (this) {
      case UserRole.hr:
        return AppRoutes.hr;
      case UserRole.staff:
        return AppRoutes.staff;
      case UserRole.family:
        return AppRoutes.family;
    }
  }

  /// Maps `/mobile/me` role strings onto a portal. Returns null when the
  /// backend role is not one of the three mobile apps.
  ///
  /// Staff portal covers nurse, caregiver, and housekeeper — the same shell
  /// with permission-scoped data from `/mobile/me` + `/mobile/home`.
  static UserRole? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (normalized.isEmpty) return null;

    if (normalized.contains('family') ||
        normalized.contains('guardian') ||
        normalized.contains('relative') ||
        normalized.contains('kin')) {
      return UserRole.family;
    }
    if (StaffKind.tryParse(normalized) != null ||
        normalized.contains('staff') ||
        normalized.contains('care_worker') ||
        normalized == 'carer') {
      return UserRole.staff;
    }
    if (normalized.contains('manager') ||
        normalized.contains('hr') ||
        normalized.contains('admin') ||
        normalized.contains('supervisor')) {
      return UserRole.hr;
    }
    return null;
  }
}

/// Care-role subtype inside the Staff portal.
///
/// Portal chrome is shared; menus and tiles follow API permissions
/// (`clients:read`, `mar:read` / `mar:write`, `incidents:read`, …).
enum StaffKind {
  nurse,
  caregiver,
  housekeeper,
  other;

  static StaffKind? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (normalized.isEmpty) return null;
    if (normalized.contains('housekeeper') ||
        normalized.contains('house_keeper')) {
      return StaffKind.housekeeper;
    }
    if (normalized.contains('caregiver') ||
        normalized.contains('care_giver') ||
        normalized.contains('care_worker') ||
        normalized == 'carer') {
      return StaffKind.caregiver;
    }
    if (normalized.contains('nurse')) {
      return StaffKind.nurse;
    }
    if (normalized.contains('staff')) {
      return StaffKind.other;
    }
    return null;
  }

  String get label {
    switch (this) {
      case StaffKind.nurse:
        return 'Nurse';
      case StaffKind.caregiver:
        return 'Caregiver';
      case StaffKind.housekeeper:
        return 'Housekeeper';
      case StaffKind.other:
        return 'Staff';
    }
  }
}
