import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/message_recipient.dart';
import 'recipient_chip.dart';

/// The bordered rounded "To" field on the "New Message" compose screen: a
/// wrap of already-added [RecipientChip]s followed by an inline text field
/// for typing more recipients.
class RecipientInputField extends StatelessWidget {
  final List<MessageRecipient> recipients;
  final TextEditingController controller;
  final ValueChanged<MessageRecipient> onRemoveRecipient;
  final VoidCallback onSubmitted;

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
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
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
            RecipientChip(recipient: recipient, onRemove: () => onRemoveRecipient(recipient)),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: ResponsiveHelper.getResponsiveWidth(context, 110)),
            child: IntrinsicWidth(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmitted(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textHeading,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Add recipient...',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textFaint,
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
