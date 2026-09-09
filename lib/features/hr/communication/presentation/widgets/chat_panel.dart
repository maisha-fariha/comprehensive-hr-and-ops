import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/communication_enums.dart';
import '../../domain/entities/hr_conversation.dart';

class ChatPanel extends StatelessWidget {
  final HrConversation? conversation;
  final List<HrChatMessage> messages;
  final TextEditingController messageController;
  final VoidCallback onSend;

  const ChatPanel({
    super.key,
    required this.conversation,
    required this.messages,
    required this.messageController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 16),
          ),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          'Select a conversation to start messaging.',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _ChatHeader(conversation: conversation!),
          const Divider(height: 1, color: AppColors.cardBorder),
          const _MonitoredBanner(),
          Expanded(
            child: ListView.builder(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.getResponsiveHeight(context, 14),
                  ),
                  child: _MessageBubble(message: messages[index]),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _Composer(
            controller: messageController,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final HrConversation conversation;

  const _ChatHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 40),
            height: ResponsiveHelper.getResponsiveSize(context, 40),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3F2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              conversation.isGroup
                  ? Icons.groups_rounded
                  : Icons.person_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 20),
              color: AppColors.secondaryTeal,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 2),
                ),
                Text(
                  conversation.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.vertical_split_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 22),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _MonitoredBanner extends StatelessWidget {
  const _MonitoredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 12,
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F9),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: AppColors.infoBlue,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Expanded(
            child: Text(
              'This conversation is monitored by the care provider. Everyone in it can see this notice. Messages are kept as a record.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.textBody,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final HrChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final outgoing = message.direction == ChatMessageDirection.outgoing;
    final bubbleColor =
        outgoing ? AppColors.secondaryTeal : const Color(0xFFF1F4F7);
    final textColor = outgoing ? Colors.white : AppColors.textHeading;
    final avatarBg =
        outgoing ? const Color(0xFFE8F1F0) : const Color(0xFFE3ECF9);
    final avatarFg =
        outgoing ? AppColors.secondaryTeal : AppColors.infoBlue;

    final avatar = Container(
      width: ResponsiveHelper.getResponsiveSize(context, 32),
      height: ResponsiveHelper.getResponsiveSize(context, 32),
      decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        message.senderInitials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: avatarFg,
        ),
      ),
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.senderName,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Text(
          message.timeLabel,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
            color: AppColors.textMuted,
          ),
        ),
      ],
    );

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: textColor,
            height: 1.35,
          ),
        ),
      ),
    );

    if (outgoing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                meta,
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 6),
                ),
                bubble,
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          avatar,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              meta,
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 6),
              ),
              bubble,
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        top: 12,
        bottom: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        13.5,
                      ),
                      color: AppColors.textHeading,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13.5,
                        ),
                        color: AppColors.textPlaceholder,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getResponsiveHeight(
                          context,
                          10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Material(
                color: AppColors.secondaryTeal,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSend,
                  child: SizedBox(
                    width: ResponsiveHelper.getResponsiveSize(context, 44),
                    height: ResponsiveHelper.getResponsiveSize(context, 44),
                    child: const Center(
                      child: AppSvgIcon(
                        'assets/icons/staff_tasks_messages/send.svg',
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            'Messages are kept as a record of the conversation.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
