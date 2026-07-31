import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_tab_overview.dart';
import '../../team_reports_assets.dart';
import 'conversation_tile.dart';
import 'stat_tile_card.dart';
import 'top_report_tile.dart';

class _TeamStatStyle {
  final String? asset;
  final IconData? materialIcon;
  final Color color;
  final Color background;

  const _TeamStatStyle({this.asset, this.materialIcon, required this.color, required this.background});
}

const Map<TeamStatTag, _TeamStatStyle> _teamStatStyles = {
  TeamStatTag.totalStaff: _TeamStatStyle(
    asset: TeamReportsAssets.totalStaff,
    color: AppColors.infoBlue,
    background: AppColors.infoIconBackground,
  ),
  TeamStatTag.onDutyNow: _TeamStatStyle(
    asset: TeamReportsAssets.onDutyNow,
    color: AppColors.activeGreen,
    background: AppColors.activeIconBackground,
  ),
  TeamStatTag.openShifts: _TeamStatStyle(
    asset: TeamReportsAssets.openShifts,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
  // No matching exported SVG for a person-add glyph; falls back to a
  // Material icon (see the feature's final report).
  TeamStatTag.vacancies: _TeamStatStyle(
    materialIcon: Icons.person_add_alt_1_rounded,
    color: AppColors.urgentAmber,
    background: AppColors.urgentIconBackground,
  ),
};

/// Content of the "Team" segment: overview stats, top reports and a recent
/// message preview.
class TeamTabView extends StatelessWidget {
  final TeamTabOverview overview;
  final VoidCallback? onViewAllStats;
  final VoidCallback? onViewAllReports;
  final VoidCallback? onViewAllMessages;

  const TeamTabView({
    super.key,
    required this.overview,
    this.onViewAllStats,
    this.onViewAllReports,
    this.onViewAllMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderRow(title: 'Team Overview', trailing: ViewAllLink(onTap: onViewAllStats)),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: overview.stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.getResponsiveHeight(context, 12),
            crossAxisSpacing: ResponsiveHelper.getResponsiveWidth(context, 12),
            // Fixed row extent (not `childAspectRatio`) so the tile's height
            // never depends on the grid's actual column width.
            mainAxisExtent: ResponsiveHelper.getResponsiveHeight(context, 78),
          ),
          itemBuilder: (context, index) {
            final stat = overview.stats[index];
            final style = _teamStatStyles[stat.tag]!;
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
        SectionHeaderRow(title: 'Top Reports', trailing: ViewAllLink(onTap: onViewAllReports)),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        SurfaceCard.card(
          padding: ResponsiveHelper.getResponsivePadding(context, left: 14, right: 14, top: 2, bottom: 2),
          child: Column(
            children: [
              for (var i = 0; i < overview.topReports.length; i++)
                TopReportTile(
                  item: overview.topReports[i],
                  showDivider: i != overview.topReports.length - 1,
                ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(title: 'Recent Messages', trailing: ViewAllLink(onTap: onViewAllMessages)),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        ConversationTile(conversation: overview.recentMessage, showUnreadBadge: false),
      ],
    );
  }
}
