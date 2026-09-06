import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import 'available_report_card.dart';
import 'stat_tile_card.dart';
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

/// Content of the "Reports" segment: overview stats and available reports.
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
