import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/top_report_item.dart';
import '../../team_reports_assets.dart';
import 'report_type_style.dart';
import 'team_reports_icon_box.dart';

/// A single row in the Team tab's "Top Reports" list: icon avatar, title,
/// a date/date-range caption and a trailing sparkline glyph.
class TopReportTile extends StatelessWidget {
  final TopReportItem item;
  final bool showDivider;
  final VoidCallback? onTap;

  const TopReportTile({
    super.key,
    required this.item,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = reportTypeStyles[item.tag]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
              )
            : null,
        padding: ResponsiveHelper.getResponsivePadding(context, top: 12, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeamReportsIconBox(
              asset: style.asset,
              materialIcon: style.materialIcon,
              color: style.color,
              background: style.background,
              boxSize: 38,
              iconSize: 18,
              radius: 11,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Row(
                    children: [
                      const AppSvgIcon(TeamReportsAssets.dateCaptionCalendar, size: 11, color: AppColors.textFaint),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      Flexible(
                        child: Text(
                          item.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            // No matching exported SVG for a bar-chart/sparkline glyph;
            // falls back to a Material icon (see the feature's final
            // report).
            Icon(
              Icons.bar_chart_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 22),
              color: style.color,
            ),
          ],
        ),
      ),
    );
  }
}
