import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_messages_enums.dart';
import '../../family_messages_constants.dart';

class _AttachmentStyle {
  final IconData icon;
  final String label;

  const _AttachmentStyle({required this.icon, required this.label});
}

/// Icon note: no matching SVGs exist in `assets/icons/*` for image/PDF/
/// document glyphs, so this uses `Icons.image_outlined`,
/// `Icons.picture_as_pdf_outlined` and `Icons.insert_drive_file_outlined`
/// as temporary stand-ins.
const Map<MessageAttachmentType, _AttachmentStyle> _attachmentStyles = {
  MessageAttachmentType.photo: _AttachmentStyle(icon: Icons.image_outlined, label: 'Photo'),
  MessageAttachmentType.pdf: _AttachmentStyle(icon: Icons.picture_as_pdf_outlined, label: 'PDF'),
  MessageAttachmentType.document: _AttachmentStyle(icon: Icons.insert_drive_file_outlined, label: 'Document'),
};

/// One of the 3 equal-width bordered rounded boxes under "Attachments
/// (Optional)" on the "New Message" compose screen: a centered icon above a
/// centered label.
class AttachmentOptionTile extends StatelessWidget {
  final MessageAttachmentType type;
  final bool selected;
  final VoidCallback onTap;

  const AttachmentOptionTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _attachmentStyles[type]!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(context, FamilyMessagesDimens.attachmentTileHeight),
        decoration: BoxDecoration(
          color: selected ? AppColors.activeBackground : AppColors.surfaceWhite,
          border: Border.all(color: selected ? AppColors.secondaryTeal : AppColors.searchBorder),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, 14),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              style.icon,
              size: ResponsiveHelper.getResponsiveSize(context, 22),
              color: selected ? AppColors.secondaryTeal : AppColors.textSecondary,
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
            Text(
              style.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: selected ? AppColors.secondaryTeal : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
