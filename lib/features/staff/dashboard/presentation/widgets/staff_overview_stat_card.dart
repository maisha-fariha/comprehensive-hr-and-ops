import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/staff_dashboard_enums.dart';
import '../../domain/entities/staff_overview_stat.dart';

class _StatTagStyle {
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color dotColor;

  const _StatTagStyle({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.dotColor,
  });
}

const Map<StaffStatTag, _StatTagStyle> _statTagStyles = {
  StaffStatTag.onShift: _StatTagStyle(
    asset: AppAssets.clock,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
    dotColor: AppColors.activeGreen,
  ),
  StaffStatTag.clients: _StatTagStyle(
    asset: AppAssets.users,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
    dotColor: AppColors.infoBlue,
  ),
  StaffStatTag.tasks: _StatTagStyle(
    asset: AppAssets.clipboardCheck,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
    dotColor: AppColors.urgentAmber,
  ),
  StaffStatTag.medications: _StatTagStyle(
    asset: AppAssets.pill,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
    dotColor: AppColors.criticalRed,
  ),
};

/// A single tile in the Staff Dashboard's "Today's Overview" stat grid.
class StaffOverviewStatCard extends StatelessWidget {
  final StaffOverviewStat stat;
  final VoidCallback? onTap;

  const StaffOverviewStatCard({super.key, required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 9);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: AppSvgIcon(style.asset, size: 21, color: style.iconColor),
                ),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(color: style.dotColor, shape: BoxShape.circle),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Column(
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
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                    color: AppColors.textHeading,
                    letterSpacing: -0.4,
                    height: 1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textSecondary,
                    height: 16 / 12.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
