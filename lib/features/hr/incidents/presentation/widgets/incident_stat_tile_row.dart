import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/incident_stat.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../incidents_constants.dart';

class _StatTagStyle {
  final String? asset;
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
    asset: AppAssets.circleError,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  IncidentStatTag.pendingReview: _StatTagStyle(
    asset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  IncidentStatTag.underReview: _StatTagStyle(
    asset: 'assets/icons/incidents/under_review.svg',
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
  IncidentStatTag.assignedInvestigators: _StatTagStyle(
    asset: 'assets/icons/incidents/assigned.svg',
    iconColor: AppColors.nightPurple,
    iconBackground: AppColors.nightBackground,
  ),
  IncidentStatTag.pendingActions: _StatTagStyle(
    asset: 'assets/icons/incidents/pending.svg',
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  IncidentStatTag.resolvedToday: _StatTagStyle(
    asset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  IncidentStatTag.thisWeek: _StatTagStyle(
    asset: 'assets/icons/incidents/statistics.svg',
    iconColor: AppColors.secondaryTeal,
    iconBackground: IncidentsColors.evidenceAccentBackground,
  ),
  IncidentStatTag.archived: _StatTagStyle(
    asset: 'assets/icons/incidents/archived.svg',
    iconColor: AppColors.textSecondary,
    iconBackground: AppColors.dividerLight,
  ),
};

/// The row of 3 summary stat tiles at the top of every Incidents tab —
/// matched to the "Open - Incidents" Figma reference (rounded-square
/// tinted icon containers).
class IncidentStatTileRow extends StatelessWidget {
  final List<IncidentStat> stats;

  const IncidentStatTileRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _IncidentStatTile(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _IncidentStatTile extends StatelessWidget {
  final IncidentStat stat;

  const _IncidentStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 6,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 20),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            child: style.asset != null
                ? AppSvgIcon(style.asset!, size: 17, color: style.iconColor)
                : Icon(
                    style.materialIcon,
                    size: ResponsiveHelper.getResponsiveSize(context, 17),
                    color: style.iconColor,
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: style.iconColor,
              letterSpacing: -0.4,
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
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
