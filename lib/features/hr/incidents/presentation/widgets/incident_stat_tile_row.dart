import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../incidents_constants.dart';

class _StatTagStyle {
  /// Existing exported Figma SVG to reuse, when one visually matches.
  final String? asset;

  /// Material Icon placeholder used when no existing SVG matches the
  /// Figma glyph (see the feature's final report for the full list of
  /// substitutions still pending a real exported asset).
  final IconData? materialIcon;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({
    this.asset,
    this.materialIcon,
    required this.iconColor,
    required this.iconBackground,
  }) : assert(asset != null || materialIcon != null);
}

const Map<IncidentStatTag, _StatTagStyle> _statTagStyles = {
  IncidentStatTag.openIncidents: _StatTagStyle(
    asset: AppAssets.alertTriangle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  IncidentStatTag.criticalCases: _StatTagStyle(
    asset: AppAssets.alertCircle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  IncidentStatTag.pendingReview: _StatTagStyle(
    asset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  IncidentStatTag.underReview: _StatTagStyle(
    materialIcon: Icons.shield_outlined,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
  IncidentStatTag.assignedInvestigators: _StatTagStyle(
    materialIcon: Icons.person_outline_rounded,
    iconColor: AppColors.nightPurple,
    iconBackground: AppColors.nightBackground,
  ),
  IncidentStatTag.pendingActions: _StatTagStyle(
    materialIcon: Icons.check_box_outlined,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  IncidentStatTag.resolvedToday: _StatTagStyle(
    materialIcon: Icons.check_circle_outline_rounded,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  IncidentStatTag.thisWeek: _StatTagStyle(
    materialIcon: Icons.show_chart_rounded,
    iconColor: AppColors.secondaryTeal,
    iconBackground: IncidentsColors.evidenceAccentBackground,
  ),
  IncidentStatTag.archived: _StatTagStyle(
    materialIcon: Icons.archive_outlined,
    iconColor: AppColors.textSecondary,
    iconBackground: AppColors.dividerLight,
  ),
};

/// The row of 3 fixed-width summary stat tiles shown at the top of every
/// Incidents tab (e.g. "4 Open Incidents", "1 Critical Cases", "3 Pending
/// Review"). Figma always shows exactly 3 tiles in a single row (never a
/// wrapping grid), so this is a plain `Row` of `Expanded` tiles rather than
/// a `GridView`.
class IncidentStatTileRow extends StatelessWidget {
  final List<IncidentStat> stats;

  const IncidentStatTileRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(child: _IncidentStatTile(stat: stats[i])),
        ],
      ],
    );
  }
}

class _IncidentStatTile extends StatelessWidget {
  final IncidentStat stat;

  const _IncidentStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: style.iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 11),
              ),
            ),
            alignment: Alignment.center,
            child: style.asset != null
                ? AppSvgIcon(style.asset!, size: 18, color: style.iconColor)
                : Icon(
                    style.materialIcon,
                    size: ResponsiveHelper.getResponsiveSize(context, 19),
                    color: style.iconColor,
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 9)),
          Text(
            stat.value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 21),
              color: style.iconColor,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textSecondary,
              height: 13 / 11,
            ),
          ),
        ],
      ),
    );
  }
}
