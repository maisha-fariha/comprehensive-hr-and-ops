import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_dashboard_enums.dart';
import '../../domain/entities/family_overview_stat.dart';

class _StatTagStyle {
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color badgeBackground;
  final String badgeLabel;

  const _StatTagStyle({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeLabel,
  });
}

const Map<StatTag, _StatTagStyle> _statTagStyles = {
  StatTag.active: _StatTagStyle(
    asset: AppAssets.users,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
    badgeBackground: AppColors.activeBackground,
    badgeLabel: 'ACTIVE',
  ),
  StatTag.urgent: _StatTagStyle(
    asset: AppAssets.alertTriangle,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
    badgeBackground: AppColors.urgentBackground,
    badgeLabel: 'URGENT',
  ),
  StatTag.due: _StatTagStyle(
    asset: AppAssets.checkCircle,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
    badgeBackground: AppColors.urgentBackground,
    badgeLabel: 'DUE',
  ),
  StatTag.review: _StatTagStyle(
    asset: AppAssets.clipboardCheck,
    iconColor: AppColors.infoBlue,
    iconBackground: AppColors.infoIconBackground,
    badgeBackground: AppColors.infoBackground,
    badgeLabel: 'REVIEW',
  ),
};

/// A single tile in the "Today's Overview" stat grid.
class FamilyOverviewStatCard extends StatelessWidget {
  final FamilyOverviewStat stat;
  final VoidCallback? onTap;

  const FamilyOverviewStatCard({super.key, required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 42);

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
                StatusBadge.pill(
                  label: style.badgeLabel,
                  background: style.badgeBackground,
                  foreground: style.iconColor,
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
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30),
                    color: AppColors.textHeading,
                    letterSpacing: -0.6,
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
                    // Figma's text box is 16px tall for a 12.5px label; pin the
                    // line height explicitly instead of relying on the font's
                    // own (platform-dependent) default metrics.
                    height: 16 / 12.5,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 6)),
                  child: Text(
                    stat.helperText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: stat.isHelperTextPositive ? AppColors.activeGreen : AppColors.textMuted,
                      // Figma's text box is 15px tall for an 11px helper label.
                      height: 15 / 11,
                    ),
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
