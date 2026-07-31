import 'package:flutter/material.dart';

/// Design tokens used by the Staff "Tasks & Messages" feature that are not
/// already covered by `lib/core/constants/app_colors.dart`/`app_dimens.dart`.
/// Kept local to this feature per the module boundary rules; centralize into
/// the shared `AppColors`/`AppDimens` later if other features end up needing
/// the same chat-bubble tones.
abstract final class StaffTasksMessagesColors {
  /// Background of an incoming chat bubble (left-aligned, from the other
  /// participant).
  static const Color incomingBubbleBackground = Color(0xFFF1F3F5);

  /// Background of an outgoing chat bubble (right-aligned, from the signed
  /// in staff member). Reuses the shared teal brand color.
  static const Color outgoingBubbleBackground = Color(0xFF0E7C7B);

  /// Background of the centered "Today" date-divider chip in the thread.
  static const Color dateDividerBackground = Color(0xFFF1F3F5);

  /// Tint used for the "Pending" task status pill and empty/outline task
  /// status indicator ring.
  static const Color pendingRingColor = Color(0xFFD8DEE6);

  const StaffTasksMessagesColors._();
}

/// Radii/spacing tokens for the chat-bubble layout on the Message Details
/// screen.
abstract final class StaffTasksMessagesDimens {
  static const double bubbleRadius = 16;
  static const double bubbleTailRadius = 4;
  static const double bubbleMaxWidthFraction = 0.74;
  static const double taskStatusDotSize = 10;
  static const double avatarSizeLarge = 44;
  static const double avatarSizeSmall = 22;
  static const double avatarSizeTiny = 18;

  const StaffTasksMessagesDimens._();
}
