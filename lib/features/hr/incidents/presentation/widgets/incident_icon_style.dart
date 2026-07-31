import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/incidents_enums.dart';

/// Visual treatment (icon + color) for an incident card's leading avatar,
/// shared by the Open/Under Review/Closed card widgets.
///
/// Icon note: none of these glyphs (heart, bandage, house) exist yet as
/// exported Figma SVGs in `assets/icons/*`, so this uses Material Icon
/// placeholders as temporary stand-ins - flagged in the feature's final
/// report. `home` is an exact visual match already; `heart` and `bandage`
/// are close semantic/visual matches; `flame` is the least certain (the
/// Figma "Fall — No Injury" glyph looks like a flame/teardrop outline, but
/// its semantic meaning doesn't obviously fit a fall incident) and should
/// be the first to be swapped for a real exported asset.
class IncidentIconStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const IncidentIconStyle({required this.icon, required this.color, required this.background});

  factory IncidentIconStyle.forKind(IncidentIconKind kind) {
    switch (kind) {
      case IncidentIconKind.heart:
        return const IncidentIconStyle(
          icon: Icons.favorite_border_rounded,
          color: AppColors.criticalRed,
          background: AppColors.criticalIconBackground,
        );
      case IncidentIconKind.bandage:
        return const IncidentIconStyle(
          icon: Icons.healing_outlined,
          color: AppColors.urgentAmber,
          background: AppColors.urgentIconBackground,
        );
      case IncidentIconKind.home:
        return const IncidentIconStyle(
          icon: Icons.home_outlined,
          color: AppColors.textSecondary,
          background: AppColors.dividerLight,
        );
      case IncidentIconKind.flame:
        return const IncidentIconStyle(
          icon: Icons.local_fire_department_outlined,
          color: AppColors.textSecondary,
          background: AppColors.dividerLight,
        );
    }
  }
}
