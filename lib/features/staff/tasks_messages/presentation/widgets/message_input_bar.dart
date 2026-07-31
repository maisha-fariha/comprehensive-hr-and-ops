import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Bottom composer bar on the Message Details screen: an attachment button,
/// a rounded text field with an inline emoji button, and a circular send
/// button.
///
/// Icon note: no matching SVGs exist in `assets/icons/*` for a paperclip,
/// emoji or send/paper-plane glyph, so this uses `Icons.attach_file_rounded`,
/// `Icons.emoji_emotions_outlined` and `Icons.send_rounded` as temporary
/// stand-ins.
class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onEmojiTap;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachmentTap,
    this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onAttachmentTap,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.attach_file_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 22),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(
              child: Container(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 999),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                            color: AppColors.textPlaceholder,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onEmojiTap,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        size: ResponsiveHelper.getResponsiveSize(context, 19),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            GestureDetector(
              onTap: onSend,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ResponsiveHelper.getResponsiveSize(context, 40),
                height: ResponsiveHelper.getResponsiveSize(context, 40),
                decoration: const BoxDecoration(color: AppColors.secondaryTeal, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  Icons.send_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 18),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
