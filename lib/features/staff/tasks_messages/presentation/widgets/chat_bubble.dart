import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../staff_tasks_messages_constants.dart';

/// A single chat row in the Message Details thread: avatar + bubble +
/// timestamp/receipt caption, aligned left for incoming and right for outgoing.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  /// Peer (contact) initials for the left avatar on incoming messages.
  final String contactInitials;

  /// When false, the side avatar is omitted (e.g. consecutive same-direction
  /// messages only show the avatar on the first bubble in the group).
  final bool showAvatar;

  static const Color _incomingBubble = Color(0xFFFFFFFF);
  static const Color _outgoingBubble = Color(0xFF137E7E);
  static const Color _incomingText = Color(0xFF203548);
  static const Color _captionColor = Color(0xFF9EA8AC);
  static const Color _seenCheckColor = Color(0xFF137E7E);

  static const Color _incomingAvatarBg = Color(0xFFE3ECF9);
  static const Color _incomingAvatarFg = Color(0xFF4775C5);
  static const Color _outgoingAvatarBg = Color(0xFFE8F1F0);
  static const Color _outgoingAvatarFg = Color(0xFF0C7065);

  static const List<BoxShadow> _bubbleShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  const ChatBubble({
    super.key,
    required this.message,
    required this.contactInitials,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.direction == MessageDirection.outgoing;
    final maxWidth = MediaQuery.sizeOf(context).width * StaffTasksMessagesDimens.bubbleMaxWidthFraction;
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 28);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 8);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);
    final initials = isOutgoing ? (message.senderInitials ?? '') : contactInitials;
    final shouldShowAvatar = showAvatar && initials.isNotEmpty;

    final avatar = _InitialsAvatar(
      initials: initials,
      size: avatarSize,
      background: isOutgoing ? _outgoingAvatarBg : _incomingAvatarBg,
      foreground: isOutgoing ? _outgoingAvatarFg : _incomingAvatarFg,
    );

    // Fixed-width avatar gutter so bubble edges stay aligned whether or not
    // the avatar is rendered.
    final avatarGutter = SizedBox(
      width: avatarSize + gap,
      child: shouldShowAvatar
          ? (isOutgoing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [SizedBox(width: gap), avatar],
                )
              : Row(
                  children: [avatar, SizedBox(width: gap)],
                ))
          : null,
    );

    return Row(
      mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutgoing) avatarGutter,
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isOutgoing ? _outgoingBubble : _incomingBubble,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: _bubbleShadow,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: isOutgoing ? Colors.white : _incomingText,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                if (isOutgoing)
                  _OutgoingReceipt(message: message)
                else
                  _IncomingCaption(timeLabel: message.timeLabel),
              ],
            ),
          ),
        ),
        if (isOutgoing) avatarGutter,
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  const _InitialsAvatar({
    required this.initials,
    required this.size,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: foreground,
          height: 1,
        ),
      ),
    );
  }
}

class _IncomingCaption extends StatelessWidget {
  final String timeLabel;

  const _IncomingCaption({required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    return Text(
      timeLabel,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
        color: ChatBubble._captionColor,
        height: 1.2,
      ),
    );
  }
}

class _OutgoingReceipt extends StatelessWidget {
  final ChatMessage message;

  const _OutgoingReceipt({required this.message});

  @override
  Widget build(BuildContext context) {
    final status = message.receiptStatus;
    final isSeen = status == 'Seen';
    final fontSize = ResponsiveHelper.getResponsiveFontSize(context, 10.5);

    if (status == null) {
      return Text(
        message.timeLabel,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: fontSize,
          color: ChatBubble._captionColor,
          height: 1.2,
        ),
      );
    }

    if (isSeen) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: ResponsiveHelper.getResponsiveSize(context, 13),
            color: ChatBubble._seenCheckColor,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
          Flexible(
            child: Text(
              '$status · ${message.timeLabel}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: fontSize,
                color: ChatBubble._captionColor,
                height: 1.2,
              ),
            ),
          ),
        ],
      );
    }

    // Delivered (and any other non-Seen status): text only, no checkmark.
    return Text(
      '$status · ${message.timeLabel}',
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w400,
        fontSize: fontSize,
        color: ChatBubble._captionColor,
        height: 1.2,
      ),
    );
  }
}
