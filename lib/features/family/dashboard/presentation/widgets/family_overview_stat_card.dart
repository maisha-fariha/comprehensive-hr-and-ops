import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_dashboard_enums.dart';
import '../../domain/entities/family_overview_stat.dart';

class _StatTagStyle {
  final String asset;
  final Color accent;
  final Color iconBackground;
  final Color badgeBackground;
  final String badgeLabel;

  const _StatTagStyle({
    required this.asset,
    required this.accent,
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeLabel,
  });
}

const Map<StatTag, _StatTagStyle> _statTagStyles = {
  StatTag.active: _StatTagStyle(
    asset: 'assets/icons/family_core/staff.svg',
    accent: Color(0xFF027A48),
    iconBackground: Color(0xFFECFDF3),
    badgeBackground: Color(0xFFECFDF3),
    badgeLabel: 'ACTIVE',
  ),
  StatTag.urgent: _StatTagStyle(
    asset: 'assets/icons/family_core/alert.svg',
    accent: Color(0xFFB42318),
    iconBackground: Color(0xFFFEF3F2),
    badgeBackground: Color(0xFFFEF3F2),
    badgeLabel: 'URGENT',
  ),
  StatTag.due: _StatTagStyle(
    asset: 'assets/icons/family_core/tasks.svg',
    accent: Color(0xFFB54708),
    iconBackground: Color(0xFFFFFAEB),
    badgeBackground: Color(0xFFFFFAEB),
    badgeLabel: 'DUE',
  ),
  StatTag.review: _StatTagStyle(
    asset: 'assets/icons/family_core/reviews.svg',
    accent: Color(0xFF2A5DA6),
    iconBackground: Color(0xFFE7EFFA),
    badgeBackground: Color(0xFFE7EFFA),
    badgeLabel: 'REVIEW',
  ),
};

/// A single tile in the "Today's Overview" 2×2 stat grid.
class FamilyOverviewStatCard extends StatelessWidget {
  final FamilyOverviewStat stat;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _helperMuted = Color(0xFF667085);
  static const Color _border = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyOverviewStatCard({super.key, required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _shadow.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            BoxShadow(
              color: _shadow.withValues(alpha: 0.05),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 8)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: AppSvgIcon(style.asset, size: 20, color: style.accent),
                ),
                const Spacer(),
                _StatusPill(
                  label: style.badgeLabel,
                  background: style.badgeBackground,
                  foreground: style.accent,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
            Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                color: _titleColor,
                letterSpacing: -0.6,
                height: 1,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: _titleColor,
                height: 1.2,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            _HelperLine(
              text: stat.helperText,
              isPositive: stat.isHelperTextPositive,
              positiveColor: style.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 9,
        vertical: 4,
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
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: foreground,
          letterSpacing: 0.3,
          height: 1.1,
        ),
      ),
    );
  }
}

class _HelperLine extends StatelessWidget {
  final String text;
  final bool isPositive;
  final Color positiveColor;

  const _HelperLine({
    required this.text,
    required this.isPositive,
    required this.positiveColor,
  });

  String get _cleanedText {
    return text
        .replaceFirst(RegExp(r'^[↑▾▴▲]\s*'), '')
        .replaceFirst(RegExp(r'^\+\s*'), '+')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? positiveColor : FamilyOverviewStatCard._helperMuted;
    final display = _cleanedText;

    if (!isPositive) {
      return Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
          color: color,
          height: 1.2,
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.arrow_upward_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 12),
          color: color,
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
              color: color,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
