import 'package:flutter/material.dart';

/// Centralized color tokens extracted from the Figma design ("Comprehensive
/// HR and Operations Platform App"). Keep this as the single source of truth
/// for color values so every feature module stays visually consistent.
abstract final class AppColors {
  // Brand / primary
  static const Color primaryNavy = Color(0xFF16293F);
  static const Color secondaryTeal = Color(0xFF0E7C7B);
  static const Color secondaryTealDark = Color(0xFF0C5E5C);
  static const Color secondaryTealDeep = Color(0xFF0E4A54);

  // Surfaces
  static const Color scaffoldBackground = Color(0xFFF4F6F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEEF1F4);
  static const Color dividerLight = Color(0xFFF1F4F7);
  static const Color searchBorder = Color(0xFFEBEEF1);
  static const Color filterButtonBackground = Color(0xFFF4F6F7);

  // Text
  static const Color textPrimary = Color(0xFF16293F);
  static const Color textHeading = Color(0xFF14263B);
  static const Color textBody = Color(0xFF3A4B60);
  static const Color textSecondary = Color(0xFF647285);
  static const Color textMuted = Color(0xFF8A97A8);
  static const Color textFaint = Color(0xFF94A3B8);
  static const Color textPlaceholder = Color(0xFF757575);
  static const Color iconChevron = Color(0xFFC3CCD6);

  // Status - critical / red
  static const Color criticalRed = Color(0xFFF44336);
  static const Color criticalBackground = Color(0xFFF4D6D6);
  static const Color criticalBackgroundSoft = Color(0xFFFDF0F0);
  static const Color criticalIconBackground = Color(0xFFFBEDED);

  // Status - urgent / amber-orange
  static const Color urgentAmber = Color(0xFFB4791C);
  static const Color urgentBackground = Color(0xFFFBF1E6);
  static const Color urgentBackgroundSoft = Color(0xFFFDF6EB);
  static const Color urgentIconBackground = Color(0xFFFBF3E9);

  // Status - success / green
  static const Color successGreen = Color(0xFF3FA66D);
  static const Color activeGreen = Color(0xFF2E8C58);
  static const Color activeBackground = Color(0xFFEAF6F0);
  static const Color activeIconBackground = Color(0xFFEDF7F1);

  // Status - info / blue
  static const Color infoBlue = Color(0xFF2A5DA6);
  static const Color infoBackground = Color(0xFFEAF0F9);
  static const Color infoIconBackground = Color(0xFFECF1FA);

  // Status - night / purple
  static const Color nightPurple = Color(0xFF6A4BC7);
  static const Color nightIndicator = Color(0xFF7C5CD6);
  static const Color nightBackground = Color(0xFFF0ECFB);

  // Schedule indicators
  static const Color morningIndicator = Color(0xFF3FA66D);
  static const Color eveningIndicator = Color(0xFFE8A33D);
  static const Color timelineDivider = Color(0xFFEDF0F3);

  // Quick action tiles
  static const Color quickActionCreateShiftBg = Color(0xFFE7F4F1);
  static const Color quickActionApproveBg = Color(0xFFEAF6F0);
  static const Color quickActionLogNoteBg = Color(0xFFEAF0F9);
  static const Color quickActionMessageBg = Color(0xFFEEF1F5);
  static const Color quickActionMessageIcon = Color(0xFF1E3A5F);

  // Bottom navigation
  static const Color navInactive = Color(0xFF9AA6B4);

  // Misc overlays / opacity based colors
  static const Color whiteOpacity13 = Color(0x21FFFFFF); // rgba(255,255,255,.13)
  static const Color whiteOpacity16 = Color(0x29FFFFFF); // rgba(255,255,255,.16)
  static const Color whiteOpacity04 = Color(0x0AFFFFFF); // rgba(255,255,255,.04)
  static const Color whiteOpacity62 = Color(0x9EFFFFFF); // rgba(255,255,255,.62)
  static const Color whiteOpacity70 = Color(0xB3FFFFFF); // rgba(255,255,255,.70)
  static const Color whiteOpacity80 = Color(0xCCFFFFFF); // rgba(255,255,255,.80)

  static const Color shadowNavy = Color(0xFF142846);
  static const Color shadowTeal = Color(0xFF0E4A54);

  const AppColors._();
}
