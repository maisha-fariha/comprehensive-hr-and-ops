import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../domain/entities/team_tab_overview.dart';
import 'conversation_tile.dart';
import 'stat_tile_card.dart';
import 'top_report_tile.dart';

class _TeamStatStyle {
  final String asset;
  final Color color;
  final Color background;
  final Color valueColor;

  const _TeamStatStyle({
    required this.asset,
    required this.color,
    required this.background,
    required this.valueColor,
  });
}

const Map<TeamStatTag, _TeamStatStyle> _teamStatStyles = {
  TeamStatTag.totalStaff: _TeamStatStyle(
    asset: 'assets/icons/team_reports/team_staff.svg',
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
    valueColor: AppColors.textHeading,
  ),
  TeamStatTag.onDutyNow: _TeamStatStyle(
    asset: 'assets/icons/team_reports/team_duty.svg',
    color: Color(0xFF2E8C58),
    background: Color(0xFFEAF6F0),
    valueColor: Color(0xFF2E8C58),
  ),
  TeamStatTag.openShifts: _TeamStatStyle(
    asset: 'assets/icons/team_reports/team_calendar.svg',
    color: Color(0xFF2A5DA6),
    background: Color(0xFFEAF0F9),
    valueColor: Color(0xFF2A5DA6),
  ),
  TeamStatTag.vacancies: _TeamStatStyle(
    asset: 'assets/icons/team_reports/team_vacancy.svg',
    color: Color(0xFFB36B21),
    background: Color(0xFFFCF5ED),
    valueColor: Color(0xFFB36B21),
  ),
};

/// Team tab content: overview stats, top reports, recent messages.
class TeamTabView extends StatelessWidget {
  final TeamTabOverview overview;
  final VoidCallback? onViewAllStats;
  final VoidCallback? onViewAllReports;
  final VoidCallback? onViewAllMessages;

  /// UI-only second preview message from the reference (not in domain model).
  static const ConversationPreview _mikePreview = ConversationPreview(
    id: 'mike-t-recent',
    senderName: 'Mike T.',
    initials: 'MT',
    timeLabel: 'Yesterday',
    previewText: 'Requesting coverage for Friday evening...',
  );

  const TeamTabView({
    super.key,
    required this.overview,
    this.onViewAllStats,
    this.onViewAllReports,
    this.onViewAllMessages,
  });

  @override
  Widget build(BuildContext context) {
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);
    final messages = [overview.recentMessage, _mikePreview];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: 'Team Overview', onViewAll: onViewAllStats),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
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
                final style = _teamStatStyles[stat.tag]!;
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
            _SectionHeader(title: 'Top Reports', onViewAll: onViewAllReports),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < overview.topReports.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              TopReportTile(item: overview.topReports[i]),
            ],
            SizedBox(height: sectionGap),
            _SectionHeader(title: 'Recent Messages', onViewAll: onViewAllMessages),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            for (var i = 0; i < messages.length; i++) ...[
              if (i > 0) SizedBox(height: cardGap),
              ConversationTile(
                conversation: messages[i],
                showUnreadBadge: false,
                showTrailingStatusDot: true,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

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
        GestureDetector(
          onTap: onViewAll,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'View all',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.secondaryTeal,
            ),
          ),
        ),
      ],
    );
  }
}
