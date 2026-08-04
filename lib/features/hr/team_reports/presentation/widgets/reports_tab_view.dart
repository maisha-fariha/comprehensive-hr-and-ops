import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import 'available_report_card.dart';
import 'stat_tile_card.dart';
import 'team_reports_icon_box.dart';
import 'team_reports_text_link.dart';

class _ReportStatStyle {
  final String asset;
  final Color color;
  final Color background;
  final Color valueColor;

  const _ReportStatStyle({
    required this.asset,
    required this.color,
    required this.background,
    required this.valueColor,
  });
}

const Map<ReportStatTag, _ReportStatStyle> _reportStatStyles = {
  ReportStatTag.generated: _ReportStatStyle(
    asset: 'assets/icons/team_reports/team_doc.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    valueColor: Color(0xFF2A5DA6),
  ),
  ReportStatTag.pendingReview: _ReportStatStyle(
    asset: 'assets/icons/team_reports/team_clock.svg',
    color: Color(0xFFB4791C),
    background: Color(0xFFFCF5ED),
    valueColor: Color(0xFFB4791C),
  ),
  ReportStatTag.critical: _ReportStatStyle(
    asset: 'assets/icons/team_reports/team_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    valueColor: Color(0xFFD64545),
  ),
  ReportStatTag.scheduled: _ReportStatStyle(
    asset: 'assets/icons/team_reports/team_schedule.svg',
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
    valueColor: Color(0xFF0E7C7B),
  ),
};

class _InsightData {
  final String title;
  final String asset;
  final Color color;
  final Color background;
  final String trendLabel;
  final bool isPositive;

  const _InsightData({
    required this.title,
    required this.asset,
    required this.color,
    required this.background,
    required this.trendLabel,
    required this.isPositive,
  });
}

const List<_InsightData> _reportInsights = [
  _InsightData(
    title: 'Attendance Trend',
    asset: 'assets/icons/team_reports/team_staff.svg',
    color: Color(0xFF6A4BC7),
    background: Color(0xFFF0ECFB),
    trendLabel: '3%',
    isPositive: true,
  ),
  _InsightData(
    title: 'Medication Compliance',
    asset: 'assets/icons/team_reports/team_heart.svg',
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
    trendLabel: '1%',
    isPositive: true,
  ),
  _InsightData(
    title: 'Incident Trend',
    asset: 'assets/icons/team_reports/team_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    trendLabel: '2%',
    isPositive: false,
  ),
];

/// Content of the "Reports" segment: overview stats, available reports,
/// and report insights.
class ReportsTabView extends StatelessWidget {
  final ReportsTabOverview overview;
  final VoidCallback? onFilterTap;

  const ReportsTabView({super.key, required this.overview, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overview.stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 10),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 10),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
          ),
          itemBuilder: (context, index) {
            final stat = overview.stats[index];
            final style = _reportStatStyles[stat.tag]!;
            return StatTileCard(
              asset: style.asset,
              color: style.color,
              background: style.background,
              value: stat.value,
              valueColor: style.valueColor,
              label: stat.label,
            );
          },
        ),
        SizedBox(height: sectionGap),
        _SectionHeader(
          title: 'Available Reports',
          trailing: TeamReportsTextLink(
            label: 'Filter',
            asset: TeamReportsAssets.filter,
            onTap: onFilterTap,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < overview.availableReports.length; i++) ...[
          if (i > 0) SizedBox(height: cardGap),
          AvailableReportCard(item: overview.availableReports[i]),
        ],
        SizedBox(height: cardGap),
        // UI-only Governance card from the reference (not in domain / repo).
        AvailableReportCard.custom(
          title: 'Compliance Audit Report',
          categoryLabel: 'Governance',
          updatedLabel: 'Updated this week',
          asset: 'assets/icons/team_reports/team_compliance.svg',
          color: const Color(0xFF2E8C58),
          background: const Color(0xFFEAF6F0),
        ),
        SizedBox(height: sectionGap),
        const _SectionHeader(title: 'Report Insights'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < _reportInsights.length; i++) ...[
          if (i > 0) SizedBox(height: cardGap),
          _ReportInsightCard(data: _reportInsights[i]),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15.5),
              color: AppColors.textHeading,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ReportInsightCard extends StatelessWidget {
  final _InsightData data;

  const _ReportInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final positive = data.isPositive;
    final badgeBg = positive ? const Color(0xFFEAF6F0) : const Color(0xFFFBEDED);
    final badgeFg = positive ? const Color(0xFF2E8C58) : const Color(0xFFD64545);
    final trendAsset = positive
        ? 'assets/icons/team_reports/team_stat_up.svg'
        : 'assets/icons/team_reports/team_stat_down.svg';

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          TeamReportsIconBox(
            asset: data.asset,
            color: data.color,
            background: data.background,
            boxSize: 40,
            iconSize: 18,
            radius: 12,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
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
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(trendAsset, size: 12, color: badgeFg),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                Text(
                  data.trendLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: badgeFg,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
