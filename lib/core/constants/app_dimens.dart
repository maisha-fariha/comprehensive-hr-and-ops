/// Spacing, radius and elevation tokens measured from the Figma design.
/// Values are the raw design-time pixels; pass them through
/// `ResponsiveHelper` at the call site to scale for tablets/other devices.
abstract final class AppDimens {
  // Radii
  static const double radiusPill = 999;
  static const double radiusCard = 18;
  static const double radiusButton = 16;
  static const double radiusIconBoxLarge = 14;
  static const double radiusIconBoxMedium = 12;
  static const double radiusIconBoxSmall = 11;
  static const double radiusBadge = 6;
  static const double radiusInput = 16;
  static const double radiusChip = 13;
  static const double radiusOrgAvatar = 8;

  // Card padding
  static const double cardPaddingHorizontal = 17;
  static const double screenPaddingHorizontal = 20;

  // Header
  static const double headerBottomGap = 20;
  static const double searchBarHeight = 52;
  static const double searchBarOverlap = 26;

  // Icon sizes
  static const double iconTiny = 16;
  static const double iconSmall = 17;
  static const double iconRegular = 18;
  static const double iconMedium = 20;
  static const double iconLarge = 21;
  static const double iconNav = 22;

  // Icon container sizes
  static const double iconBoxSmall = 38;
  static const double iconBoxMedium = 42;
  static const double iconBoxLarge = 46;

  const AppDimens._();
}
