import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/conversation_preview.dart';
import '../../domain/entities/tasks_messages_enums.dart';

class _AvatarPalette {
  final Color color;
  final Color background;

  const _AvatarPalette(this.color, this.background);
}

const List<_AvatarPalette> _avatarPalette = [
  _AvatarPalette(Color(0xFF2A5DA6), Color(0xFFE8F0FE)),
  _AvatarPalette(Color(0xFF2D8A56), Color(0xFFE8F6EF)),
  _AvatarPalette(Color(0xFF7C3AED), Color(0xFFEDE9FE)),
];

class _PriorityStyle {
  final Color color;
  final Color background;
  final String label;

  const _PriorityStyle({
    required this.color,
    required this.background,
    required this.label,
  });
}

const Map<MessagePriority, _PriorityStyle> _priorityStyles = {
  MessagePriority.highPriority: _PriorityStyle(
    color: Color(0xFFB91C1C),
    background: Color(0xFFFEE2E2),
    label: 'High Priority',
  ),
  MessagePriority.routine: _PriorityStyle(
    color: Color(0xFF2563EB),
    background: Color(0xFFDBEAFE),
    label: 'Routine',
  ),
  MessagePriority.general: _PriorityStyle(
    color: Color(0xFF64748B),
    background: Color(0xFFF1F5F9),
    label: 'General',
  ),
};

/// Conversation list card for the Messages tab.
class ConversationRowTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback? onTap;

  static const Color _titleColor = Color(0xFF1A2B48);
  static const Color _metaColor = Color(0xFF94A3B8);
  static const Color _onlineDot = Color(0xFF0E7C7B);

  const ConversationRowTile({super.key, required this.conversation, this.onTap});

  static _AvatarPalette _paletteFor(ConversationPreview conversation) {
    return switch (conversation.id) {
      'angela-m' => _avatarPalette[0],
      'priya-k' => _avatarPalette[1],
      'robert-t' => _avatarPalette[2],
      _ => _avatarPalette[conversation.id.hashCode.abs() % _avatarPalette.length],
    };
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 48);
    final palette = _paletteFor(conversation);
    final priorityStyle = _priorityStyles[conversation.priority]!;
    // Mock data pairs online + unread; use [isOnline] for both UI cues.
    final isUnread = conversation.isOnline;
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final statusDot = ResponsiveHelper.getResponsiveSize(context, 11);
    final unreadDot = ResponsiveHelper.getResponsiveSize(context, 8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowNavy.withValues(alpha: 0.04),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
          ),
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
                      shape: BoxShape.circle,
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
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: statusDot,
                        height: statusDot,
                        decoration: BoxDecoration(
                          color: _onlineDot,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceWhite,
                            width: 2,
                          ),
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
                              color: _titleColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                        Text(
                          conversation.timeLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                            color: _metaColor,
                            height: 1.2,
                          ),
                        ),
                        if (isUnread) ...[
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                          Container(
                            width: unreadDot,
                            height: unreadDot,
                            decoration: const BoxDecoration(
                              color: _onlineDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                    Text(
                      conversation.previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                        color: isUnread ? _titleColor : _metaColor,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                    Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityStyle.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        priorityStyle.label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: priorityStyle.color,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
