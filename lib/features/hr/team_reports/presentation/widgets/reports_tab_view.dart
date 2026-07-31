import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/reports_tab_overview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import 'available_report_card.dart';
import 'stat_tile_card.dart';
import 'team_reports_text_link.dart';

class _ReportStatStyle {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const _ReportStatStyle({this.asset, this.materialIcon, required this.color, required this.background});
}

const Map<ReportStatTag, _ReportStatStyle> _reportStatStyles = {
  // No matching exported SVG for a generic document/file glyph; falls back
  // to a Material icon (see the feature's final report).
  ReportStatTag.generated: _ReportStatStyle(
    materialIcon: Icons.description_outlined,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  ReportStatTag.pendingReview: _ReportStatStyle(
    asset: TeamReportsAssets.pendingReview,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  ReportStatTag.critical: _ReportStatStyle(
    asset: TeamReportsAssets.critical,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
  ReportStatTag.scheduled: _ReportStatStyle(
    asset: TeamReportsAssets.scheduled,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
};

/// Content of the "Reports" segment: overview stats and the list of
/// available reports.
class ReportsTabView extends StatelessWidget {
  final ReportsTabOverview overview;
  final VoidCallback? onFilterTap;

  const ReportsTabView({super.key, required this.overview, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overview.stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
          ),
          itemBuilder: (context, index) {
            final stat = overview.stats[index];
            final style = _reportStatStyles[stat.tag]!;
            return StatTileCard(
              asset: style.asset,
              materialIcon: style.materialIcon,
              color: style.color,
              background: style.background,
              value: stat.value,
              label: stat.label,
            );
          },
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Available Reports',
          trailing: TeamReportsTextLink(
            label: 'Filter',
            asset: TeamReportsAssets.filter,
            onTap: onFilterTap,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < overview.availableReports.length; i++) ...[
          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          AvailableReportCard(item: overview.availableReports[i]),
        ],
      ],
    );
  }
}
