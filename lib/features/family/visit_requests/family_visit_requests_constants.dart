import 'package:flutter/material.dart';

/// Design tokens specific to the Family "Visit Requests" feature that don't
/// belong in `lib/core/constants` (which is shared across every feature and
/// must not be edited by this feature). Colors already present in
/// `AppColors` (amber/green/red for Pending/Approved/Rejected, purple for
/// "Reschedule Requested") are reused directly rather than introducing new
/// values - only the two tones with no existing equivalent are added here.
abstract final class FamilyVisitRequestsColors {
  /// Light teal tint used for the "Visit" type tag pill and for the small
  /// icon boxes on the Request Details screen. Sampled from the Figma
  /// screenshots (~#DFF3F1); pairs with the existing
  /// `AppColors.secondaryTeal` as its foreground color.
  static const Color visitTagBackground = Color(0xFFDFF3F1);

  /// Neutral grey pill used for the closed-out "Completed"/"Cancelled"
  /// statuses on the "History" tab - no equivalent grey status tone exists
  /// in `AppColors` yet (its status colors are all red/amber/green/blue/
  /// purple).
  static const Color neutralStatusBackground = Color(0xFFEBEEF1);
  static const Color neutralStatusForeground = Color(0xFF64748B);

  const FamilyVisitRequestsColors._();
}
