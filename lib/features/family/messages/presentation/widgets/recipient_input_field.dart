import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/message_recipient.dart';
import 'recipient_chip.dart';

/// Bordered "To" field: recipient chips + inline "Add recipient..." input.
class RecipientInputField extends StatelessWidget {
  final List<MessageRecipient> recipients;
  final TextEditingController controller;
  final ValueChanged<MessageRecipient> onRemoveRecipient;
  final VoidCallback onSubmitted;

  static const Color _border = Color(0xFFE2E8EE);
  static const Color _text = Color(0xFF1A2B48);
  static const Color _hint = Color(0xFF9AA8B8);

  const RecipientInputField({
    super.key,
    required this.recipients,
    required this.controller,
    required this.onRemoveRecipient,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Wrap(
        spacing: ResponsiveHelper.getResponsiveWidth(context, 8),
        runSpacing: ResponsiveHelper.getResponsiveHeight(context, 8),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final recipient in recipients)
            RecipientChip(
              recipient: recipient,
              onRemove: () => onRemoveRecipient(recipient),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: ResponsiveHelper.getResponsiveWidth(context, 110),
            ),
            child: IntrinsicWidth(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmitted(),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                  color: _text,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveHeight(context, 4),
                  ),
                  hintText: 'Add recipient...',
                  hintStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13.5,
                    ),
                    color: _hint,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
