import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/attention_alert.dart';
import '../../domain/entities/dashboard_enums.dart';

class _SeverityStyle {
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color badgeBackground;
  final String badgeLabel;

  const _SeverityStyle({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeLabel,
  });
}

const Map<AlertSeverity, _SeverityStyle> _severityStyles = {
  AlertSeverity.critical: _SeverityStyle(
    asset: AppAssets.alertTriangle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalBackground,
    badgeBackground: AppColors.criticalBackgroundSoft,
    badgeLabel: 'Critical',
  ),
  AlertSeverity.urgent: _SeverityStyle(
    asset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentBackground,
    badgeBackground: AppColors.urgentBackgroundSoft,
    badgeLabel: 'Urgent',
  ),
};

/// A single row inside the "Needs Attention" card.
class AttentionAlertTile extends StatelessWidget {
  final AttentionAlert alert;
  final bool showDivider;
  final VoidCallback? onTap;

  const AttentionAlertTile({
    super.key,
    required this.alert,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _severityStyles[alert.severity]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 38);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
              )
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 17, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              child: AppSvgIcon(style.asset, size: 18, color: style.iconColor),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    alert.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            StatusBadge.chip(
              label: style.badgeLabel,
              background: style.badgeBackground,
              foreground: style.iconColor,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            const AppSvgIcon(AppAssets.chevronRight, size: 18, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}
