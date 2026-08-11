import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Design tokens used by the Family "Messages" feature that are not already
/// covered by `lib/core/constants/app_colors.dart`/`app_dimens.dart`. Kept
/// local to this feature per the module boundary rules; centralize into the
/// shared `AppColors`/`AppDimens` later if other features end up needing the
/// same tones.
abstract final class FamilyMessagesColors {
  /// Background of the already-added recipient chip in the "To" field on the
  /// "New Message" compose screen.
  static const Color recipientChipBackground = AppColors.quickActionCreateShiftBg;

  const FamilyMessagesColors._();
}

/// Sizing tokens for the conversation list rows and compose-screen widgets.
abstract final class FamilyMessagesDimens {
  static const double conversationAvatarSize = 46;
  static const double unreadBadgeSize = 18;
  static const double recipientChipAvatarSize = 20;
  static const double attachmentTileHeight = 90;
  static const double composeTextAreaMinHeight = 120;

  const FamilyMessagesDimens._();
}
