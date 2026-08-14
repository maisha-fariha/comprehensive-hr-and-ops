import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../family_messages_constants.dart';

/// Multiline bordered textarea under the "Message" label.
class ComposeMessageField extends StatelessWidget {
  final TextEditingController controller;

  static const Color _border = Color(0xFFE2E8EE);
  static const Color _text = Color(0xFF1A2B48);
  static const Color _hint = Color(0xFF9AA8B8);

  const ComposeMessageField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.getResponsiveHeight(
          context,
          FamilyMessagesDimens.composeTextAreaMinHeight,
        ),
      ),
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 5,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: _text,
          height: 1.4,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Write your message...',
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: _hint,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
