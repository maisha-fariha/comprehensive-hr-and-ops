import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'domain/entities/hr_preference_item.dart';

abstract final class HrProfileSettingsConstants {
  static const Color profileAvatarBackground = Color(0xFFEBCABF);
  static const Color profileAvatarForeground = Color(0xFF8D5F4D);

  static const Color linkedItemAvatarBackground = AppColors.infoBackground;
  static const Color linkedItemAvatarForeground = AppColors.infoBlue;

  static const Color preferenceIconBackground = Color(0xFFEFF6F4);
  static const Color preferenceIconForeground = Color(0xFF0E7C7B);

  static const String _moreIcons = 'assets/icons/family_more';

  static String preferenceIconAsset(HrPreferenceType type) {
    return switch (type) {
      HrPreferenceType.notifications => '$_moreIcons/notification.svg',
      HrPreferenceType.helpCenter => '$_moreIcons/help.svg',
      HrPreferenceType.contactSupport => '$_moreIcons/message.svg',
      HrPreferenceType.privacySecurity => '$_moreIcons/shield_outlined.svg',
    };
  }

  const HrProfileSettingsConstants._();
}
