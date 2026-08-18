import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/conversation_preview.dart';
import 'team_reports_icon_box.dart';

class _AvatarPalette {
  final Color color;
  final Color background;

  const _AvatarPalette(this.color, this.background);
}

const _AvatarPalette _sarahPalette = _AvatarPalette(
  Color(0xFF6A4BC7),
  Color(0xFFF0ECFB),
);

const _AvatarPalette _mikePalette = _AvatarPalette(
  Color(0xFF2A5DA6),
  Color(0xFFEAF0F9),
);

const List<_AvatarPalette> _fallbackPalettes = [
  _sarahPalette,
  _mikePalette,
  _AvatarPalette(AppColors.activeGreen, AppColors.activeIconBackground),
  _AvatarPalette(AppColors.urgentAmber, AppColors.urgentIconBackground),
];

_AvatarPalette _paletteFor(ConversationPreview conversation) {
  final key = conversation.initials.toUpperCase();
  if (key == 'SJ') return _sarahPalette;
  if (key == 'MT') return _mikePalette;
  return _fallbackPalettes[conversation.id.hashCode.abs() % _fallbackPalettes.length];
}

/// Message-thread row for Team "Recent Messages" and Messages "Conversations".
class ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final bool showUnreadBadge;

  /// When true (Team tab preview), use circular avatars and a teal status
  /// dot on the preview row instead of a numeric unread badge.
  final bool showTrailingStatusDot;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.showUnreadBadge = true,
    this.showTrailingStatusDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTeamPreview = showTrailingStatusDot;
    final hasUnread = conversation.unreadCount > 0;
    final showNumericBadge = showUnreadBadge && hasUnread && !isTeamPreview;
    final showPreviewDot = isTeamPreview && (hasUnread || conversation.isOnline);
    // Unread (or Team status-dot rows) use a deeper preview style.
    final emphasizePreview = hasUnread || showPreviewDot;
    final palette = _paletteFor(conversation);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final avatarDesignSize = isTeamPreview ? 46.0 : 44.0;
    final avatarCorner = 12.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LeadingAvatar(
              conversation: conversation,
              palette: palette,
              designSize: avatarDesignSize,
              cornerRadius: avatarCorner,
              showOnlineDot: !isTeamPreview && conversation.isOnline && !conversation.isGroup,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTeamPreview)
                    Row(
                      children: [
                        Expanded(child: _NameText(conversation.senderName)),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                        _TimeText(conversation.timeLabel),
                      ],
                    )
                  else
                    _NameText(conversation.senderName),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: emphasizePreview ? FontWeight.w600 : FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                            color: emphasizePreview
                                ? AppColors.textHeading
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (showPreviewDot) ...[
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 8),
                          height: ResponsiveHelper.getResponsiveSize(context, 8),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isTeamPreview) ...[
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimeText(conversation.timeLabel),
                  if (showNumericBadge) ...[
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _NameText extends StatelessWidget {
  final String name;

  const _NameText(this.name);

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        color: AppColors.textHeading,
        height: 1.2,
      ),
    );
  }
}

class _TimeText extends StatelessWidget {
  final String label;

  const _TimeText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
        color: AppColors.textFaint,
      ),
    );
  }
}

class _LeadingAvatar extends StatelessWidget {
  final ConversationPreview conversation;
  final _AvatarPalette palette;
  final double designSize;
  final double cornerRadius;
  final bool showOnlineDot;

  const _LeadingAvatar({
    required this.conversation,
    required this.palette,
    required this.designSize,
    required this.cornerRadius,
    required this.showOnlineDot,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = conversation.isGroup
        ? TeamReportsIconBox(
            asset: 'assets/icons/team_reports/team_staff.svg',
            color: const Color(0xFF0E7C7B),
            background: const Color(0xFFE3F3F1),
            boxSize: designSize,
            iconSize: 20,
            radius: cornerRadius,
          )
        : Container(
            width: ResponsiveHelper.getResponsiveSize(context, designSize),
            height: ResponsiveHelper.getResponsiveSize(context, designSize),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, cornerRadius),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              conversation.initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: palette.color,
                height: 1,
              ),
            ),
          );

    if (!showOnlineDot) return child;

    final dot = ResponsiveHelper.getResponsiveSize(context, 10);
    final border = ResponsiveHelper.getResponsiveSize(context, 2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: const Color(0xFF2E8C58),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: border),
            ),
          ),
        ),
      ],
    );
  }
}
