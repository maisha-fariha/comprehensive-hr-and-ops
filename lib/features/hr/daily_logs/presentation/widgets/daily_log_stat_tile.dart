import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../daily_logs_constants.dart';
import '../../domain/entities/daily_log_summary_stat.dart';
import '../../domain/entities/daily_logs_enums.dart';

class _StatTagStyle {
  final String? svgAsset;
  final IconData? materialIcon;
  final Color iconColor;
  final Color iconBackground;

  const _StatTagStyle({
    this.svgAsset,
    this.materialIcon,
    required this.iconColor,
    required this.iconBackground,
  });
}

// Every tile reuses an existing dashboard icon/color pair except
// "Active Handovers", which has no matching exchange/swap glyph in
// `assets/icons/dashboard` - `Icons.swap_horiz_rounded` is used as a
// temporary stand-in there (flagged in the final report).
const Map<DailyLogStatTag, _StatTagStyle> _statTagStyles = {
  DailyLogStatTag.submittedToday: _StatTagStyle(
    svgAsset: AppAssets.checkCircle,
    iconColor: AppColors.activeGreen,
    iconBackground: AppColors.activeIconBackground,
  ),
  DailyLogStatTag.pendingReview: _StatTagStyle(
    svgAsset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  DailyLogStatTag.flaggedNotes: _StatTagStyle(
    svgAsset: AppAssets.flag,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  DailyLogStatTag.missingLogs: _StatTagStyle(
    svgAsset: AppAssets.alertCircle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
  DailyLogStatTag.overdue: _StatTagStyle(
    svgAsset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  DailyLogStatTag.followUpRequired: _StatTagStyle(
    svgAsset: AppAssets.alertTriangle,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  DailyLogStatTag.activeHandovers: _StatTagStyle(
    materialIcon: Icons.swap_horiz_rounded,
    iconColor: AppColors.secondaryTeal,
    iconBackground: AppColors.quickActionCreateShiftBg,
  ),
  DailyLogStatTag.pendingAcknowledgement: _StatTagStyle(
    svgAsset: AppAssets.clock,
    iconColor: AppColors.urgentAmber,
    iconBackground: AppColors.urgentIconBackground,
  ),
  DailyLogStatTag.urgentNotes: _StatTagStyle(
    svgAsset: AppAssets.alertTriangle,
    iconColor: AppColors.criticalRed,
    iconBackground: AppColors.criticalIconBackground,
  ),
};

/// A single tile in the "3 stat tiles" row shown at the top of every Daily
/// Logs tab. Styled after the Dashboard's `OverviewStatCard`, but centered
/// (icon → value → label) to match the reference screenshot's layout.
class DailyLogStatTile extends StatelessWidget {
  final DailyLogSummaryStat stat;

  const DailyLogStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final style = _statTagStyles[stat.tag]!;
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard);

    final content = Container(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: stat.isHighlighted ? null : Border.all(color: AppColors.cardBorder),
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
            child: style.svgAsset != null
                ? AppSvgIcon(style.svgAsset!, size: 19, color: style.iconColor)
                : Icon(
                    style.materialIcon,
                    size: ResponsiveHelper.getResponsiveSize(context, 19),
                    color: style.iconColor,
                  ),
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

    if (!stat.isHighlighted) return content;

    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: DailyLogsConstants.flaggedHighlightBorder,
        radius: radius,
      ),
      child: content,
    );
  }
}

/// Draws a dashed rounded-rectangle border. Used for the "Flagged Notes"
/// tile's highlighted-selection treatment - implemented by hand (rather than
/// pulling in a dashed-border package) since no new dependencies may be
/// added to this feature module.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  static const double strokeWidth = 1.4;
  static const double dashWidth = 4;
  static const double dashSpace = 3;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
