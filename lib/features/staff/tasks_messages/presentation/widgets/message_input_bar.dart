import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Bottom composer bar on the Message Details screen: attachment button,
/// pill text field with inline emoji, and circular send.
class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onEmojiTap;

  static const Color _iconColor = Color(0xFF64748B);
  static const Color _attachBg = Color(0xFFF5F7F9);
  static const Color _fieldBg = Color(0xFFF7F9FA);
  static const Color _fieldBorder = Color(0xFFE2E8EE);
  static const Color _hintColor = Color(0xFF9AA6B2);
  static const Color _sendBg = Color(0xFF0E7C7B);

  static const String _attachAsset = 'assets/icons/staff_tasks_messages/add_link.svg';
  static const String _emojiAsset = 'assets/icons/staff_tasks_messages/emoji.svg';
  static const String _sendAsset = 'assets/icons/staff_tasks_messages/send.svg';

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachmentTap,
    this.onEmojiTap,
  });

  @override
  Widget build(BuildContext context) {
    final attachSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final sendSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onAttachmentTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: attachSize,
                height: attachSize,
                decoration: BoxDecoration(
                  color: _attachBg,
                  borderRadius: BorderRadius.circular(radius),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(_attachAsset, size: 20, color: _iconColor),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: ResponsiveHelper.getResponsiveHeight(context, 44),
                ),
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: _fieldBg,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 999),
                  ),
                  border: Border.all(color: _fieldBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveHeight(context, 10),
                          ),
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                            color: _hintColor,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    GestureDetector(
                      onTap: onEmojiTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveHeight(context, 8),
                        ),
                        child: const AppSvgIcon(_emojiAsset, size: 20, color: _iconColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            GestureDetector(
              onTap: onSend,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: sendSize,
                height: sendSize,
                decoration: BoxDecoration(
                  color: _sendBg,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330E7C7B),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(_sendAsset, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
