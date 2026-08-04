import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_stat_tile_data.dart';

class _StatTagStyle {
  final String svgAsset;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({
    required this.svgAsset,
    required this.iconColor,
    required this.iconBackground,
  });
}

const Map<MedicationStatTag, _StatTagStyle> _statTagStyles = {
  MedicationStatTag.compliance: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_compliance.svg',
    iconColor: Color(0xFF2E8C58),
    iconBackground: Color(0xFFEAF6F0),
  ),
  MedicationStatTag.dueToday: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_clock.svg',
    iconColor: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFEAF0F9),
  ),
  MedicationStatTag.missedCount: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_cross_circle.svg',
    iconColor: Color(0xFFD64545),
    iconBackground: Color(0xFFFBEDED),
  ),
  MedicationStatTag.refusedCount: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_refused.svg',
    iconColor: Color(0xFFC7761B),
    iconBackground: Color(0xFFFBF1E6),
  ),
  MedicationStatTag.missedToday: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_cross_circle.svg',
    iconColor: Color(0xFFD64545),
    iconBackground: Color(0xFFFBEDED),
  ),
  MedicationStatTag.criticalMissed: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_alert.svg',
    iconColor: Color(0xFFA82F2F),
    iconBackground: Color(0xFFF4E4E4),
  ),
  MedicationStatTag.totalRefused: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_refused.svg',
    iconColor: Color(0xFFC7761B),
    iconBackground: Color(0xFFFBF1E6),
  ),
  MedicationStatTag.needsFollowUp: _StatTagStyle(
    svgAsset: 'assets/icons/medication/medication_follow_up.svg',
    iconColor: Color(0xFFA8641A),
    iconBackground: Color(0xFFFBF1E6),
  ),
};

/// Stat tile: soft icon box + accent value + muted label.
/// Used by Missed/Refused tabs (and any other caller of this widget).
class MedicationStatTile extends StatelessWidget {
  final MedicationStatTileData stat;

  const MedicationStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
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
            child: AppSvgIcon(style.svgAsset, size: 19, color: style.iconColor),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: style.iconColor,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textSecondary,
                    height: 1.2,
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
