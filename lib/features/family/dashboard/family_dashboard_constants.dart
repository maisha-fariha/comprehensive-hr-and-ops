import 'package:flutter/material.dart';

/// Design tokens used by the Family Dashboard feature that are not already
/// covered by `lib/core/constants/app_colors.dart`/`app_dimens.dart`. Kept
/// local to this feature per the module boundary rules.
abstract final class FamilyDashboardColors {
  /// Background tint behind the header avatar's placeholder person glyph.
  /// The Figma design shows a real resident photo here; until a real asset
  /// pipeline exists, this backs a `Icons.person` stand-in (see
  /// `FamilyDashboardHeader`).
  static const Color avatarPlaceholderBackground = Color(0xFFEAF6F0);
  static const Color avatarPlaceholderIcon = Color(0xFF0E7C7B);

  const FamilyDashboardColors._();
}
