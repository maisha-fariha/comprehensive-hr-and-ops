import 'package:flutter/material.dart';

/// Colors/values introduced by the Figma "Incidents" screens that have no
/// equivalent in the shared `lib/core/constants/app_colors.dart` yet. Kept
/// local to this feature per project convention; centralize these in
/// `AppColors` later if other features start needing the same tones.
abstract final class IncidentsColors {
  /// Light teal accent used for the "Evidence" wizard-step number badge and
  /// the "This Week" closed-incidents stat icon. Sampled from the Figma
  /// screenshots (~#DFF3F1); pairs with the existing `AppColors.secondaryTeal`
  /// as its foreground color.
  static const Color evidenceAccentBackground = Color(0xFFDFF3F1);

  const IncidentsColors._();
}
