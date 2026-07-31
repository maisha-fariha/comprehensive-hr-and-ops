import 'package:flutter/material.dart';

/// Colors/values introduced by the Figma Staff "Incidents" screens that
/// have no equivalent in the shared `lib/core/constants/app_colors.dart`
/// yet. Kept local to this feature per project convention; centralize
/// these in `AppColors` later if other features start needing the same
/// tones.
abstract final class StaffIncidentsColors {
  /// Light teal tint used for the numbered section badges ("1", "2", "3")
  /// on the Create Incident form. Sampled from the Figma screenshot
  /// (~#DFF3F1); pairs with the existing `AppColors.secondaryTeal` as its
  /// foreground color.
  static const Color sectionBadgeBackground = Color(0xFFDFF3F1);

  const StaffIncidentsColors._();
}
