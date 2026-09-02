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
    if (normalized.contains('housekeeper') ||
        normalized.contains('house_keeper')) {
      return UserRole.staff;
    }
    if (normalized.contains('staff') ||
        normalized.contains('caregiver') ||
        normalized.contains('care_worker') ||
        normalized.contains('nurse') ||
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
