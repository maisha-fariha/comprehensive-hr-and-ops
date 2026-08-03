import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';

/// Visual treatment (icon asset + color) for an incident card's leading
/// avatar, shared by the Open/Under Review/Closed card widgets.
///
/// Uses exported SVGs from `assets/icons/` when available; falls back to a
/// Material icon only when no matching asset exists.
class IncidentIconStyle {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const IncidentIconStyle({
    this.asset,
    this.materialIcon,
    required this.color,
    required this.background,
  }) : assert(asset != null || materialIcon != null);

  factory IncidentIconStyle.forKind(IncidentIconKind kind) {
    switch (kind) {
      case IncidentIconKind.heart:
        return const IncidentIconStyle(
          asset: 'assets/icons/daily_logs/daily_log_heart.svg',
          color: AppColors.criticalRed,
          background: AppColors.criticalIconBackground,
        );
      case IncidentIconKind.bandage:
        return const IncidentIconStyle(
          asset: 'assets/icons/incidents/capsule.svg',
          color: AppColors.urgentAmber,
          background: AppColors.urgentIconBackground,
        );
      case IncidentIconKind.home:
        return const IncidentIconStyle(
          asset: 'assets/icons/daily_logs/daily_log_home.svg',
          color: AppColors.textSecondary,
          background: AppColors.dividerLight,
        );
      case IncidentIconKind.flame:
        return const IncidentIconStyle(
          asset: 'assets/icons/incidents/fire_outlined.svg',
          color: AppColors.textSecondary,
          background: AppColors.dividerLight,
        );
    }
  }
}
