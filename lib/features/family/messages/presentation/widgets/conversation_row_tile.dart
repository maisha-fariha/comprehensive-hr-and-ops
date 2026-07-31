import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../family_messages_constants.dart';

class _AvatarPalette {
  final Color background;
  final Color foreground;

  const _AvatarPalette(this.background, this.foreground);
}

const Map<ConversationAccent, _AvatarPalette> _avatarPalette = {
  ConversationAccent.orange: _AvatarPalette(AppColors.urgentIconBackground, AppColors.urgentAmber),
  ConversationAccent.blue: _AvatarPalette(AppColors.infoIconBackground, AppColors.infoBlue),
  ConversationAccent.green: _AvatarPalette(AppColors.activeIconBackground, AppColors.activeGreen),
  ConversationAccent.purple: _AvatarPalette(AppColors.nightBackground, AppColors.nightPurple),
};

/// A single row in the "Messages" list screen's conversation list: an
/// avatar (initials, or an icon for team/group chats), name + role/team
/// subtitle, a truncated preview line, a top-right timestamp and an
/// optional unread-count badge below it.
///
/// Icon note: no matching SVGs exist in `assets/icons/*` for a
/// building/team or people/group glyph, so this uses
/// `Icons.apartment_rounded` and `Icons.groups_rounded` as temporary
/// stand-ins for [ConversationAvatarType.team]/[ConversationAvatarType.group]
/// avatars.
class ConversationRowTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback? onTap;

  const ConversationRowTile({super.key, required this.conversation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, FamilyMessagesDimens.conversationAvatarSize);
    final palette = _avatarPalette[conversation.accent]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
              ),
              alignment: Alignment.center,
              child: _AvatarGlyph(conversation: conversation, color: palette.foreground),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    conversation.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                  Text(
                    conversation.previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.timeLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: AppColors.textFaint,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  _UnreadBadge(count: conversation.unreadCount),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarGlyph extends StatelessWidget {
  final ConversationPreview conversation;
  final Color color;

  const _AvatarGlyph({required this.conversation, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (conversation.avatarType) {
      case ConversationAvatarType.initials:
        return Text(
          conversation.initials,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
            color: color,
          ),
        );
      case ConversationAvatarType.team:
        return Icon(Icons.apartment_rounded, size: ResponsiveHelper.getResponsiveSize(context, 20), color: color);
      case ConversationAvatarType.group:
        return Icon(Icons.groups_rounded, size: ResponsiveHelper.getResponsiveSize(context, 20), color: color);
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, FamilyMessagesDimens.unreadBadgeSize);

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
      decoration: const BoxDecoration(color: AppColors.secondaryTeal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
