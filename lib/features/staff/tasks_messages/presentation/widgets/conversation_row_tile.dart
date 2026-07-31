import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/tasks_messages_enums.dart';

class _AvatarPalette {
  final Color color;
  final Color background;

  const _AvatarPalette(this.color, this.background);
}

const List<_AvatarPalette> _avatarPalette = [
  _AvatarPalette(AppColors.infoBlue, AppColors.infoIconBackground),
  _AvatarPalette(AppColors.nightPurple, AppColors.nightBackground),
  _AvatarPalette(AppColors.activeGreen, AppColors.activeIconBackground),
];

class _PriorityStyle {
  final Color color;
  final Color background;
  final String label;

  const _PriorityStyle({required this.color, required this.background, required this.label});
}

const Map<MessagePriority, _PriorityStyle> _priorityStyles = {
  MessagePriority.highPriority: _PriorityStyle(
    color: AppColors.criticalRed,
    background: AppColors.criticalBackground,
    label: 'High Priority',
  ),
  MessagePriority.routine: _PriorityStyle(
    color: AppColors.textSecondary,
    background: AppColors.dividerLight,
    label: 'Routine',
  ),
  MessagePriority.general: _PriorityStyle(
    color: AppColors.textSecondary,
    background: AppColors.dividerLight,
    label: 'General',
  ),
};

/// A single row in the "Messages" tab's conversation list: an avatar with an
/// optional online-status dot, name + timestamp, a preview line, and a
/// trailing-below priority pill.
class ConversationRowTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback? onTap;

  const ConversationRowTile({super.key, required this.conversation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 46);
    final palette = _avatarPalette[conversation.id.hashCode.abs() % _avatarPalette.length];
    final priorityStyle = _priorityStyles[conversation.priority]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
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
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 7)),
                  StatusBadge.pill(
                    label: priorityStyle.label,
                    background: priorityStyle.background,
                    foreground: priorityStyle.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
