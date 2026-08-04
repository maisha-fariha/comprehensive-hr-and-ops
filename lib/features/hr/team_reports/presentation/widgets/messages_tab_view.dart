import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/messages_tab_overview.dart';
import '../../domain/entities/team_reports_enums.dart';
import '../../team_reports_assets.dart';
import 'announcement_card.dart';
import 'conversation_tile.dart';
import 'stat_tile_card.dart';
import 'team_reports_text_link.dart';

class _MessageStatStyle {
  final String asset;
  final Color color;
  final Color background;
  final Color valueColor;

  const _MessageStatStyle({
    required this.asset,
    required this.color,
    required this.background,
    required this.valueColor,
  });
}

const Map<MessageStatTag, _MessageStatStyle> _messageStatStyles = {
  MessageStatTag.unread: _MessageStatStyle(
    asset: TeamReportsAssets.unreadMessages,
    color: Color(0xFF0E7C7B),
    background: Color(0xFFE3F3F1),
    valueColor: Color(0xFF0E7C7B),
  ),
  MessageStatTag.urgent: _MessageStatStyle(
    asset: 'assets/icons/team_reports/team_alert.svg',
    color: Color(0xFFD64545),
    background: Color(0xFFFBEDED),
    valueColor: Color(0xFFD64545),
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
    final sectionGap = ResponsiveHelper.getResponsiveHeight(context, 18);
    final cardGap = ResponsiveHelper.getResponsiveHeight(context, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < overview.stats.length; i++) ...[
              if (i > 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final stat = overview.stats[i];
                    final style = _messageStatStyles[stat.tag]!;
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
              ),
            ],
          ],
        ),
        SizedBox(height: sectionGap),
        _SectionHeader(
          title: 'Conversations',
          trailing: TeamReportsTextLink(
            label: 'Mark all read',
            onTap: onMarkAllRead,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < overview.conversations.length; i++) ...[
          if (i > 0) SizedBox(height: cardGap),
          ConversationTile(conversation: overview.conversations[i]),
        ],
        SizedBox(height: sectionGap),
        const _SectionHeader(title: 'Important Announcements'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < overview.announcements.length; i++) ...[
          if (i > 0) SizedBox(height: cardGap),
          AnnouncementCard(announcement: overview.announcements[i]),
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
