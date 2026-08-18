import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../family_messages_constants.dart';

class _AvatarPalette {
  final Color background;
  final Color foreground;

  const _AvatarPalette(this.background, this.foreground);
}

const Map<ConversationAccent, _AvatarPalette> _avatarPalette = {
  ConversationAccent.orange: _AvatarPalette(Color(0xFFFBF0E4), Color(0xFFC4883A)),
  ConversationAccent.blue: _AvatarPalette(Color(0xFFE8F0FA), Color(0xFF2A5DA6)),
  ConversationAccent.green: _AvatarPalette(Color(0xFFE8F6EE), Color(0xFF2E8C58)),
  ConversationAccent.purple: _AvatarPalette(Color(0xFFF0ECFB), Color(0xFF6A4BC7)),
};

/// A single conversation card on the Family Messages list.
class ConversationRowTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _subtitleColor = Color(0xFF0E7C7B);
  static const Color _previewColor = Color(0xFF7A8798);
  static const Color _timeColor = Color(0xFF9AA8B8);
  static const Color _cardBorder = Color(0xFFDCEBEA);
  static const Color _shadow = Color(0xFF142846);
  static const Color _badge = Color(0xFF0E7C7B);
  static const String _teamIcon = 'assets/icons/family_messages/team.svg';

  const ConversationRowTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(
      context,
      FamilyMessagesDimens.conversationAvatarSize,
    );
    final palette = _avatarPalette[conversation.accent]!;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: _shadow.withValues(alpha: 0.04),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 1)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
            ),
            BoxShadow(
              color: _shadow.withValues(alpha: 0.05),
              offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 6)),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: palette.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _AvatarGlyph(
                  conversation: conversation,
                  color: palette.foreground,
                ),
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
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          15,
                        ),
                        color: _titleColor,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                    Text(
                      conversation.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: _subtitleColor,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 5),
                    ),
                    Text(
                      conversation.previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: _previewColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.timeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        11,
                      ),
                      color: _timeColor,
                      height: 1.2,
                    ),
                  ),
                  if (conversation.unreadCount > 0) ...[
                    const Spacer(),
                    _UnreadBadge(count: conversation.unreadCount),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarGlyph extends StatelessWidget {
  final ConversationPreview conversation;
  final Color color;

  const _AvatarGlyph({
    required this.conversation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (conversation.avatarType) {
      case ConversationAvatarType.initials:
        return Text(
          conversation.initials,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: color,
            height: 1,
          ),
        );
      case ConversationAvatarType.team:
      case ConversationAvatarType.group:
        return AppSvgIcon(
          ConversationRowTile._teamIcon,
          size: 20,
          color: color,
        );
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(
      context,
      FamilyMessagesDimens.unreadBadgeSize,
    );

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 5),
      decoration: const BoxDecoration(
        color: ConversationRowTile._badge,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
