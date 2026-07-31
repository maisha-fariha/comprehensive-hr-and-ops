import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../domain/entities/messages_tab_overview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import '../../team_reports_constants.dart';
import 'announcement_card.dart';
import 'conversation_tile.dart';
import 'stat_tile_card.dart';
import 'team_reports_text_link.dart';

class _MessageStatStyle {
  final String asset;
  final Color color;
  final Color background;

  const _MessageStatStyle({required this.asset, required this.color, required this.background});
}

const Map<MessageStatTag, _MessageStatStyle> _messageStatStyles = {
  MessageStatTag.unread: _MessageStatStyle(
    asset: TeamReportsAssets.unreadMessages,
    color: AppColors.secondaryTeal,
    background: TeamReportsColors.medicationTealBackground,
  ),
  MessageStatTag.urgent: _MessageStatStyle(
    asset: TeamReportsAssets.urgentMessages,
    color: AppColors.criticalRed,
    background: AppColors.criticalIconBackground,
  ),
};

/// Content of the "Messages" segment: overview stats, conversations and
/// important announcements.
class MessagesTabView extends StatelessWidget {
  final MessagesTabOverview overview;
  final VoidCallback? onMarkAllRead;

  const MessagesTabView({super.key, required this.overview, this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < overview.stats.length; i++) ...[
              if (i != 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Builder(builder: (context) {
                  final stat = overview.stats[i];
                  final style = _messageStatStyles[stat.tag]!;
                  return StatTileCard(
                    asset: style.asset,
                    color: style.color,
                    background: style.background,
                    value: stat.value,
                    label: stat.label,
                  );
                }),
              ),
            ],
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        SectionHeaderRow(
          title: 'Conversations',
          trailing: TeamReportsTextLink(label: 'Mark all read', onTap: onMarkAllRead),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < overview.conversations.length; i++) ...[
          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          ConversationTile(conversation: overview.conversations[i]),
        ],
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
        const SectionHeaderRow(title: 'Important Announcements'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < overview.announcements.length; i++) ...[
          if (i != 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          AnnouncementCard(announcement: overview.announcements[i]),
        ],
      ],
    );
  }
}
