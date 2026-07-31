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
}
