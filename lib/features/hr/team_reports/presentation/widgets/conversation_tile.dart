import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../team_reports_assets.dart';
import 'team_reports_icon_box.dart';

class _AvatarPalette {
  final Color color;
  final Color background;

  const _AvatarPalette(this.color, this.background);
}

const List<_AvatarPalette> _avatarPalette = [
  _AvatarPalette(AppColors.nightPurple, AppColors.nightBackground),
  _AvatarPalette(AppColors.infoBlue, AppColors.infoIconBackground),
  _AvatarPalette(AppColors.activeGreen, AppColors.activeIconBackground),
  _AvatarPalette(AppColors.urgentAmber, AppColors.urgentIconBackground),
];

/// A single message-thread row. Reused by the Team tab's compact "Recent
/// Messages" preview ([showUnreadBadge]: false) and the Messages tab's full
/// "Conversations" list ([showUnreadBadge]: true).
class ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final bool showUnreadBadge;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.showUnreadBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 46);
    final hasUnread = conversation.unreadCount > 0;
    final palette = _avatarPalette[conversation.id.hashCode.abs() % _avatarPalette.length];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (conversation.isGroup)
                  TeamReportsIconBox(
                    asset: TeamReportsAssets.groupAvatar,
                    color: AppColors.textMuted,
                    background: AppColors.dividerLight,
                    boxSize: avatarSize,
                    iconSize: 20,
                    radius: 14,
                  )
                else
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
                    child: Text(
                      conversation.initials,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                        color: palette.color,
                      ),
                    ),
                  ),
                if (conversation.isOnline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 13),
                      height: ResponsiveHelper.getResponsiveSize(context, 13),
                      decoration: BoxDecoration(
                        color: AppColors.activeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceWhite, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                      Text(
                        conversation.timeLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    conversation.previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (showUnreadBadge && hasUnread) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 20),
                height: ResponsiveHelper.getResponsiveSize(context, 20),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryTeal,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${conversation.unreadCount}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
