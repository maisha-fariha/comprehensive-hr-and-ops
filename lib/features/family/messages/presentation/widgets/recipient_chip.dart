import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/message_recipient.dart';
import '../../family_messages_constants.dart';

/// A single already-added recipient chip in the "To" field on the "New
/// Message" compose screen: a small avatar, the recipient's name, and a
/// remove ("x") icon.
///
/// Icon note: no matching SVG exists in `assets/icons/*` for a plain "x"
/// remove glyph, so this uses `Icons.close_rounded` as a temporary
/// stand-in.
class RecipientChip extends StatelessWidget {
  final MessageRecipient recipient;
  final VoidCallback onRemove;

  const RecipientChip({super.key, required this.recipient, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, FamilyMessagesDimens.recipientChipAvatarSize);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: FamilyMessagesColors.recipientChipBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(color: AppColors.secondaryTeal, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              recipient.initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          Text(
            recipient.name,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 15),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
