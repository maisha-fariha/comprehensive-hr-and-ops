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
  final bool isLoading;
  final bool isSending;
  final bool readOnly;
  final VoidCallback? onBack;
  final VoidCallback? onHide;
  final VoidCallback? onShowParticipants;
  final VoidCallback? onUnarchive;

  /// Card chrome for the side-by-side layout. A full-screen thread turns this off.
  final bool framed;

  const ChatPanel({
    super.key,
    required this.conversation,
    required this.messages,
    required this.messageController,
    required this.onSend,
    this.isLoading = false,
    this.isSending = false,
    this.readOnly = false,
    this.onBack,
    this.onHide,
    this.onShowParticipants,
    this.onUnarchive,
    this.framed = true,
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
          border: Border.all(
            color: AppColors.cardBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          'No conversation selected.',
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
        borderRadius: framed
            ? BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 16),
              )
            : null,
        border: framed ? Border.all(color: AppColors.cardBorder) : null,
      ),
      child: Column(
        children: [
          _ChatHeader(
            conversation: conversation!,
            onBack: onBack,
            onHide: onHide,
            onShowParticipants: onShowParticipants,
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          if (conversation!.isMonitored) const _MonitoredBanner(),
          Expanded(
            child: isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              13.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveHelper.getResponsiveHeight(
                                context,
                                14,
                              ),
                            ),
                            child: _MessageBubble(message: messages[index]),
                          );
                        },
                      ),
          ),
          if (conversation!.isArchived) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            _ArchivedBar(onUnarchive: onUnarchive),
          ] else if (!readOnly) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            _Composer(
              controller: messageController,
              onSend: isSending ? null : onSend,
              isSending: isSending,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final HrConversation conversation;
  final VoidCallback? onBack;
  final VoidCallback? onHide;
  final VoidCallback? onShowParticipants;

  const _ChatHeader({
    required this.conversation,
    this.onBack,
    this.onHide,
    this.onShowParticipants,
  });

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
          if (onBack != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back,
                semanticLabel: 'Back',
                size: ResponsiveHelper.getResponsiveSize(context, 22),
                color: AppColors.textHeading,
              ),
            ),
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
                GestureDetector(
                  onTap: onShowParticipants,
                  child: Text(
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
                ),
              ],
            ),
          ),
          if (onHide != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onHide,
              icon: Icon(
                Icons.visibility_off_outlined,
                semanticLabel: 'Hide conversation',
                size: ResponsiveHelper.getResponsiveSize(context, 20),
                color: AppColors.textMuted,
              ),
            ),
          if (onShowParticipants != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onShowParticipants,
              icon: Icon(
                Icons.people_alt_outlined,
                semanticLabel: 'Participants',
                size: ResponsiveHelper.getResponsiveSize(context, 20),
                color: AppColors.textMuted,
              ),
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

class _ArchivedBar extends StatelessWidget {
  final VoidCallback? onUnarchive;

  const _ArchivedBar({this.onUnarchive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'This conversation is archived — read only.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onUnarchive != null)
            TextButton.icon(
              onPressed: onUnarchive,
              icon: Icon(
                Icons.unarchive_outlined,
                size: ResponsiveHelper.getResponsiveSize(context, 16),
                color: AppColors.secondaryTeal,
              ),
              label: Text(
                'Un-archive',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.secondaryTeal,
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
  final VoidCallback? onSend;
  final bool isSending;

  const _Composer({
    required this.controller,
    required this.onSend,
    this.isSending = false,
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
                    enabled: !isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend?.call(),
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
                    child: Center(
                      child: isSending
                          ? SizedBox(
                              width: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                              height: ResponsiveHelper.getResponsiveSize(
                                context,
                                18,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const AppSvgIcon(
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
