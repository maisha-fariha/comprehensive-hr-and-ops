import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/top_report_item.dart';
import 'team_reports_icon_box.dart';

class _ReportVisual {
  final String asset;
  final Color color;
  final Color background;
  final int activeBarIndex;

  const _ReportVisual({
    required this.asset,
    required this.color,
    required this.background,
    required this.activeBarIndex,
  });
}

const Map<ReportTypeTag, _ReportVisual> _reportVisuals = {
  ReportTypeTag.dailyCensus: _ReportVisual(
    asset: 'assets/icons/team_reports/team_doc.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    activeBarIndex: 3,
  ),
  ReportTypeTag.incidentAnalysis: _ReportVisual(
    asset: 'assets/icons/team_reports/team_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    activeBarIndex: 2,
  ),
  ReportTypeTag.medicationCompliance: _ReportVisual(
    asset: 'assets/icons/team_reports/team_heart.svg',
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
    activeBarIndex: 4,
  ),
  ReportTypeTag.staffAttendance: _ReportVisual(
    asset: 'assets/icons/team_reports/team_staff.svg',
    color: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
    activeBarIndex: 1,
  ),
};

/// Top Reports row — icon, title/date, and mini sparkline bars.
class TopReportTile extends StatelessWidget {
  final TopReportItem item;
  final bool showDivider;
  final VoidCallback? onTap;

  const TopReportTile({
    super.key,
    required this.item,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _reportVisuals[item.tag]!;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            TeamReportsIconBox(
              asset: visual.asset,
              color: visual.color,
              background: visual.background,
              boxSize: 40,
              iconSize: 18,
              radius: 12,
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
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: AppColors.textHeading,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Row(
                    children: [
                      const AppSvgIcon(
                        'assets/icons/team_reports/team_calendar.svg',
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
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
            _Sparkline(activeIndex: visual.activeBarIndex),
          ],
        ),
      ),
    );
  }
}

/// Five-bar mini chart; [activeIndex] (0–4) is highlighted navy.
class _Sparkline extends StatelessWidget {
  final int activeIndex;

  static const Color _active = Color(0xFF1E3A5F);
  static const Color _inactive = Color(0xFFD7E3F0);

  /// Relative bar heights (bottom-aligned).
  static const List<double> _heights = [10, 16, 12, 20, 14];

  const _Sparkline({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final maxH = ResponsiveHelper.getResponsiveHeight(context, 22);
    final barW = ResponsiveHelper.getResponsiveWidth(context, 3.5);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 2.5);

    return SizedBox(
      height: maxH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _heights.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: barW,
              height: ResponsiveHelper.getResponsiveHeight(context, _heights[i]),
              decoration: BoxDecoration(
                color: i == activeIndex ? _active : _inactive,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
