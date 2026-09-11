import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/available_report_item.dart';
import '../../domain/entities/report_export_item.dart';
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

/// Reports tab: KPIs, available reports, insights, analytics, exports, documents.
class ReportsTabView extends StatelessWidget {
  final ReportsTabOverview overview;
  final VoidCallback? onFilterTap;
  final ValueChanged<AvailableReportItem>? onExportReport;
  final ValueChanged<ReportExportItem>? onDownloadExport;

  const ReportsTabView({
    super.key,
    required this.overview,
    this.onFilterTap,
    this.onExportReport,
    this.onDownloadExport,
  });

  @override
  Widget build(BuildContext context) {
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final docsSummary = overview.documentsSummary;

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
        if (overview.availableReports.isEmpty)
          const _EmptyHint('No report summaries for this period.')
        else
          for (var i = 0; i < overview.availableReports.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            AvailableReportCard(
              item: overview.availableReports[i],
              onTap: onExportReport == null
                  ? null
                  : () => onExportReport!(overview.availableReports[i]),
            ),
          ],
        if (overview.insights.isNotEmpty) ...[
          SizedBox(height: sectionGap),
          const _SectionHeader(title: 'Report Insights'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < overview.insights.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            _InsightTile(
              title: overview.insights[i].title,
              trend: overview.insights[i].trendLabel,
              detail: overview.insights[i].detail,
              isUp: overview.insights[i].isUp,
            ),
          ],
        ],
        if (overview.analytics.isNotEmpty) ...[
          SizedBox(height: sectionGap),
          const _SectionHeader(title: 'Analytics'),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          for (var i = 0; i < overview.analytics.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            _SimpleRowCard(
              title: overview.analytics[i].title,
              value: overview.analytics[i].valueLabel,
              subtitle: overview.analytics[i].subtitle,
            ),
          ],
        ],
        SizedBox(height: sectionGap),
        const _SectionHeader(title: 'Exports'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (overview.exports.isEmpty)
          const _EmptyHint('No exports yet. Tap a report to create one.')
        else
          for (var i = 0; i < overview.exports.length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            _ExportTile(
              item: overview.exports[i],
              onDownload: onDownloadExport == null
                  ? null
                  : () => onDownloadExport!(overview.exports[i]),
            ),
          ],
        SizedBox(height: sectionGap),
        const _SectionHeader(title: 'Documents'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (docsSummary != null)
          Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
            ),
            child: Text(
              '${docsSummary.total} docs · ${docsSummary.expiringSoon} expiring · ${docsSummary.missingMandatory} missing mandatory',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (overview.documents.isEmpty)
          const _EmptyHint('No documents found.')
        else
          for (var i = 0; i < overview.documents.take(8).length; i++) ...[
            if (i > 0) SizedBox(height: cardGap),
            _SimpleRowCard(
              title: overview.documents[i].title,
              value: overview.documents[i].statusLabel,
              subtitle: overview.documents[i].updatedLabel ?? '',
            ),
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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final String trend;
  final String detail;
  final bool isUp;

  const _InsightTile({
    required this.title,
    required this.trend,
    required this.detail,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUp ? const Color(0xFF2E8C58) : const Color(0xFFD64545);
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trend,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRowCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SimpleRowCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.secondaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final ReportExportItem item;
  final VoidCallback? onDownload;

  const _ExportTile({required this.item, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reportKey,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Text(
                  '${item.status} · ${item.format.toUpperCase()}'
                  '${item.createdLabel.isEmpty ? '' : ' · ${item.createdLabel}'}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (item.isReady)
            TextButton(
              onPressed: onDownload,
              child: Text(
                'Download',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryTeal,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
