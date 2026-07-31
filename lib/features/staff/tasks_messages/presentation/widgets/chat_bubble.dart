import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tasks_messages_enums.dart';
import '../../staff_tasks_messages_constants.dart';

/// A single chat row in the Message Details thread: the message bubble plus
/// its timestamp/receipt caption, aligned left for incoming messages and
/// right for outgoing ones.
///
/// Icon note: the small "Seen"/"Delivered" receipt glyphs have no matching
/// SVG in `assets/icons/*`, so this uses `Icons.done_all_rounded` and
/// `Icons.done_rounded` as temporary stand-ins.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.direction == MessageDirection.outgoing;
    final maxWidth = MediaQuery.sizeOf(context).width * StaffTasksMessagesDimens.bubbleMaxWidthFraction;

    return Row(
      mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOutgoing
                      ? StaffTasksMessagesColors.outgoingBubbleBackground
                      : StaffTasksMessagesColors.incomingBubbleBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, StaffTasksMessagesDimens.bubbleRadius),
                    ),
                    topRight: Radius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, StaffTasksMessagesDimens.bubbleRadius),
                    ),
                    bottomLeft: Radius.circular(
                      ResponsiveHelper.getResponsiveRadius(
                        context,
                        isOutgoing
                            ? StaffTasksMessagesDimens.bubbleRadius
                            : StaffTasksMessagesDimens.bubbleTailRadius,
                      ),
                    ),
                    bottomRight: Radius.circular(
                      ResponsiveHelper.getResponsiveRadius(
                        context,
                        isOutgoing
                            ? StaffTasksMessagesDimens.bubbleTailRadius
                            : StaffTasksMessagesDimens.bubbleRadius,
                      ),
                    ),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: isOutgoing ? Colors.white : AppColors.textBody,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
              if (isOutgoing) _OutgoingReceipt(message: message) else _IncomingCaption(message: message),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomingCaption extends StatelessWidget {
  final ChatMessage message;

  const _IncomingCaption({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: ResponsiveHelper.getResponsiveWidth(context, 4)),
      child: Text(
        message.timeLabel,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
          color: AppColors.textFaint,
        ),
      ),
    );
  }
}

class _OutgoingReceipt extends StatelessWidget {
  final ChatMessage message;

  const _OutgoingReceipt({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSeen = message.receiptStatus == 'Seen';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.receiptStatus != null) ...[
          Icon(
            isSeen ? Icons.done_all_rounded : Icons.done_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 12),
            color: isSeen ? AppColors.secondaryTeal : AppColors.textFaint,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
          Text(
            '${message.receiptStatus} · ${message.timeLabel}',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: AppColors.textFaint,
            ),
          ),
        ] else
          Text(
            message.timeLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
              color: AppColors.textFaint,
            ),
          ),
        if (message.senderInitials != null) ...[
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.avatarSizeTiny),
            height: ResponsiveHelper.getResponsiveSize(context, StaffTasksMessagesDimens.avatarSizeTiny),
            decoration: const BoxDecoration(color: AppColors.secondaryTealDeep, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              message.senderInitials!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 8.5),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
