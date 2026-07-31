import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

class _StatTagStyle {
  final String svgAsset;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({required this.svgAsset, required this.iconColor, required this.iconBackground});
}

// Every tile reuses an existing dashboard icon/color pair - no Material
// icon stand-ins are needed for this feature's stat tiles.
const Map<StaffDailyLogStatTag, _StatTagStyle> _statTagStyles = {
  StaffDailyLogStatTag.submittedToday: _StatTagStyle(
    svgAsset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  StaffDailyLogStatTag.pendingReview: _StatTagStyle(
    svgAsset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  StaffDailyLogStatTag.flaggedNotes: _StatTagStyle(
    svgAsset: AppAssets.flag,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
};

/// A single tile in the "3 stat tiles" row shown at the top of every Staff
/// Daily Logs tab: icon → value → label, matching the reference
/// screenshots.
class StaffDailyLogStatTile extends StatelessWidget {
  final StaffDailyLogSummaryStat stat;

  const StaffDailyLogStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
          ),
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: style.iconBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
              ),
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(style.svgAsset, size: 19, color: style.iconColor),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            stat.value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
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
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
