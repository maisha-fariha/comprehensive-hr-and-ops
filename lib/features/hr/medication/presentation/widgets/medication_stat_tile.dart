import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_stat_tile_data.dart';

class _StatTagStyle {
  /// A Figma-exported SVG to reuse from `assets/icons/dashboard`, if one
  /// exists with a matching glyph. `null` when no existing asset matches,
  /// in which case [materialIcon] is rendered instead.
  final String? svgAsset;
  final IconData? materialIcon;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({
    this.svgAsset,
    this.materialIcon,
    required this.iconColor,
    required this.iconBackground,
  }) : assert(svgAsset != null || materialIcon != null);
}

// NOTE: `missedCount`/`missedToday` (a red "x-circle") and
// `refusedCount`/`totalRefused` (an amber "no-entry"/power icon) have no
// matching SVG in assets/icons/dashboard|common|nav, and the Figma MCP
// asset-download tool is unavailable this round (monthly quota exhausted),
// so these two use Material Icons placeholders instead of hand-authored
// SVGs. See the feature's implementation report for the full list.
const Map<MedicationStatTag, _StatTagStyle> _statTagStyles = {
  MedicationStatTag.compliance: _StatTagStyle(
    svgAsset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  MedicationStatTag.dueToday: _StatTagStyle(
    svgAsset: AppAssets.clock,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
  MedicationStatTag.missedCount: _StatTagStyle(
    materialIcon: Icons.cancel_rounded,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  MedicationStatTag.refusedCount: _StatTagStyle(
    materialIcon: Icons.block_rounded,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  MedicationStatTag.missedToday: _StatTagStyle(
    materialIcon: Icons.cancel_rounded,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  MedicationStatTag.criticalMissed: _StatTagStyle(
    svgAsset: AppAssets.alertTriangle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  MedicationStatTag.totalRefused: _StatTagStyle(
    materialIcon: Icons.block_rounded,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  MedicationStatTag.needsFollowUp: _StatTagStyle(
    svgAsset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
};

/// A single stat tile: colored icon box on the left, value + label stacked
/// on the right. Used for the Overview tab's 2x2 grid and the Missed/
/// Refused tabs' 2-tile rows.
class MedicationStatTile extends StatelessWidget {
  final MedicationStatTileData stat;

  const MedicationStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: style.iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: style.svgAsset != null
                ? AppSvgIcon(style.svgAsset!, size: 19, color: style.iconColor)
                : Icon(
                    style.materialIcon,
                    size: ResponsiveHelper.getResponsiveSize(context, 19),
                    color: style.iconColor,
                  ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
                    color: style.iconColor,
                    height: 1.1,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
