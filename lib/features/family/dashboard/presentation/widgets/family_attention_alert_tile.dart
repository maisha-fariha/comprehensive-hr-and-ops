import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_attention_alert.dart';
import '../../domain/entities/family_dashboard_enums.dart';

class _SeverityStyle {
  final String asset;
  final Color iconColor;
  final Color iconBackground;
  final Color badgeBackground;
  final Color badgeForeground;
  final String badgeLabel;

  const _SeverityStyle({
    required this.asset,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.badgeLabel,
  });
}

const String _alertAsset = 'assets/icons/family_core/alert.svg';
const String _clockAsset = 'assets/icons/family_core/clock.svg';

const Map<AlertSeverity, _SeverityStyle> _severityStyles = {
  AlertSeverity.critical: _SeverityStyle(
    asset: _alertAsset,
    iconColor: Color(0xFFE53935),
    iconBackground: Color(0xFFFDECEC),
    badgeBackground: Color(0xFFFDECEC),
    badgeForeground: Color(0xFFE53935),
    badgeLabel: 'Critical',
  ),
  AlertSeverity.urgent: _SeverityStyle(
    asset: _clockAsset,
    iconColor: Color(0xFFD98324),
    iconBackground: Color(0xFFFBF1E6),
    badgeBackground: Color(0xFFFBF1E6),
    badgeForeground: Color(0xFFD98324),
    badgeLabel: 'Urgent',
  ),
};

/// A single row inside the "Needs Attention" card.
class FamilyAttentionAlertTile extends StatelessWidget {
  final FamilyAttentionAlert alert;
  final bool showDivider;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _subtitleColor = Color(0xFF8A97A8);
  static const Color _dividerColor = Color(0xFFEEF1F4);
  static const Color _chevronColor = Color(0xFFC3CCD6);

  const FamilyAttentionAlertTile({
    super.key,
    required this.alert,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _severityStyles[alert.severity]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 44);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: _dividerColor)),
              )
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 14, bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(style.asset, size: 20, color: style.iconColor),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
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
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: _titleColor,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    alert.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: _subtitleColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _StatusChip(
              label: style.badgeLabel,
              background: style.badgeBackground,
              foreground: style.badgeForeground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
            const AppSvgIcon(AppAssets.chevronRight, size: 18, color: _chevronColor),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: foreground,
          height: 1.1,
        ),
      ),
    );
  }
}
