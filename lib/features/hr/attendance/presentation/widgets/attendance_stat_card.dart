import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../attendance_constants.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_stat.dart';

class _StatToneStyle {
  final Color iconColor;
  final Color iconBackground;

  const _StatToneStyle({required this.iconColor, required this.iconBackground});
}

const Map<AttendanceStatTone, _StatToneStyle> _toneStyles = {
  AttendanceStatTone.positive: _StatToneStyle(
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  AttendanceStatTone.warning: _StatToneStyle(
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  AttendanceStatTone.critical: _StatToneStyle(
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  AttendanceStatTone.info: _StatToneStyle(
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
  ),
};

/// A single small tile in the stat row shown at the top of every
/// Attendance tab (e.g. "14 On Time", "18.5h Total OT Hours").
class AttendanceStatCard extends StatelessWidget {
  final AttendanceStat stat;

  const AttendanceStatCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _toneStyles[stat.tone]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxSmall);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14, horizontal: 6),
      child: SizedBox(
        height: ResponsiveHelper.getResponsiveHeight(context, AttendanceDimens.statTileHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxSmall),
                ),
              ),
              alignment: Alignment.center,
              child: stat.iconAsset != null
                  ? AppSvgIcon(stat.iconAsset!, size: 17, color: style.iconColor)
                  : Icon(
                      stat.iconData,
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
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, AttendanceDimens.statValueFontSize),
                color: AppColors.textHeading,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, AttendanceDimens.statLabelFontSize),
                color: AppColors.textSecondary,
                height: 14 / AttendanceDimens.statLabelFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
