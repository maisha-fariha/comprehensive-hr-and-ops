import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';

/// "Attachments" section near the bottom of the "Daily Note" screen. The
/// reference screenshot cuts this section off right after its heading, so
/// the "Photo" / "Files" picker row is a plausible reconstruction
/// consistent with a typical attachment picker.
class DailyNoteAttachmentsSection extends StatelessWidget {
  final VoidCallback? onAddPhoto;
  final VoidCallback? onAddFiles;

  const DailyNoteAttachmentsSection({super.key, this.onAddPhoto, this.onAddFiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderRow(title: 'Attachments'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        Row(
          children: [
            Expanded(
              child: _AttachmentButton(
                icon: Icons.camera_alt_rounded,
                label: 'Photo',
                onTap: onAddPhoto,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Expanded(
              child: _AttachmentButton(
                icon: Icons.attach_file_rounded,
                label: 'Files',
                onTap: onAddFiles,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Neither a camera nor a paperclip glyph has a matching SVG in
// `assets/icons/*`, so this uses Material `Icons.camera_alt_rounded` and
// `Icons.attach_file_rounded` as temporary stand-ins - flagged in the final
// report.
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _AttachmentButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 17), color: AppColors.secondaryTeal),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: AppColors.secondaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
