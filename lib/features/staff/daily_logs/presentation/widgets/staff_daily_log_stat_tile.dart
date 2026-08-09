import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/staff_daily_log_summary_stat.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

class _StatTagStyle {
  final String svgAsset;
  final Color valueColor;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({
    required this.svgAsset,
    required this.valueColor,
    required this.iconColor,
    required this.iconBackground,
  });
}

/// Icons from `assets/icons/staff_daily_logs/`.
const Map<StaffDailyLogStatTag, _StatTagStyle> _statTagStyles = {
  StaffDailyLogStatTag.submittedToday: _StatTagStyle(
    svgAsset: 'assets/icons/staff_daily_logs/circle_check.svg',
    valueColor: Color(0xFF2E8C58),
    iconColor: Color(0xFF2E8C58),
    iconBackground: Color(0xFFE6F6EE),
  ),
  StaffDailyLogStatTag.pendingReview: _StatTagStyle(
    svgAsset: 'assets/icons/staff_daily_logs/clock.svg',
    valueColor: Color(0xFFD97706),
    iconColor: Color(0xFFD97706),
    iconBackground: Color(0xFFFFF4E5),
  ),
  StaffDailyLogStatTag.flaggedNotes: _StatTagStyle(
    svgAsset: 'assets/icons/staff_daily_logs/flag.svg',
    valueColor: Color(0xFFE5484D),
    iconColor: Color(0xFFE5484D),
    iconBackground: Color(0xFFFFEBEE),
  ),
};

/// A single tile in the top stats row: circular icon → colored value →
/// muted two-line-capable label on a white elevated card.
class StaffDailyLogStatTile extends StatelessWidget {
  final StaffDailyLogSummaryStat stat;

  const StaffDailyLogStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
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
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(style.svgAsset, size: 18, color: style.iconColor),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              color: style.valueColor,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
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
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
