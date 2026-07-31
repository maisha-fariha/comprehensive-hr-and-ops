import 'package:flutter/material.dart';

/// Colors used by the "Team & Reports" feature that are not already covered
/// by `lib/core/constants/app_colors.dart`. Kept local to this feature per
/// the module boundary rules; centralize into `AppColors` later if other
/// features end up needing the same mint/teal tone.
abstract final class TeamReportsColors {
  /// Light mint/teal background used behind the "Medication Compliance"
  /// report icon (Team tab's "Top Reports" row and Reports tab's
  /// "Available Reports" card) and the "Unread Messages" stat tile icon.
  /// None of the existing status background tokens (`activeIconBackground`,
  /// `infoIconBackground`, etc.) match this teal hue.
  static const Color medicationTealBackground = Color(0xFFE3F3F1);

  const TeamReportsColors._();
}
