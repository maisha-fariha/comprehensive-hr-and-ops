import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../family_messages_constants.dart';

/// The large bordered rounded multiline textarea under the "Message" label
/// on the "New Message" compose screen.
class ComposeMessageField extends StatelessWidget {
  final TextEditingController controller;

  const ComposeMessageField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.getResponsiveHeight(context, FamilyMessagesDimens.composeTextAreaMinHeight),
      ),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 4,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textHeading,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Write your message...',
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
            color: AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}
