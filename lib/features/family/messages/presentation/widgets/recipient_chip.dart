import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../domain/entities/message_recipient.dart';
import '../../family_messages_constants.dart';

/// Recipient chip inside the "To" field: teal avatar, name, and remove "x".
class RecipientChip extends StatelessWidget {
  final MessageRecipient recipient;
  final VoidCallback onRemove;

  static const Color _fill = Color(0xFFE7F4F1);
  static const Color _border = Color(0xFFB7DDD7);
  static const Color _teal = Color(0xFF0E7C7B);
  static const Color _name = Color(0xFF0C5E5C);

  const RecipientChip({
    super.key,
    required this.recipient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveHelper.getResponsiveSize(
      context,
      FamilyMessagesDimens.recipientChipAvatarSize,
    );

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        left: 5,
        right: 8,
        top: 5,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: _fill,
        border: Border.all(color: _border),
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
            decoration: const BoxDecoration(
              color: _teal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              recipient.initials,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9),
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          Text(
            recipient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: _name,
              height: 1.15,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 15),
              color: _teal,
            ),
          ),
        ],
      ),
    );
  }
}
