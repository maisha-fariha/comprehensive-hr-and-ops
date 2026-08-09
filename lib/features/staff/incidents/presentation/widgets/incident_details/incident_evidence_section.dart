import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import 'section_label.dart';

/// "EVIDENCE & ATTACHMENTS" section on Incident Details.
///
/// File rows match the Figma details reference (not yet on [IncidentDetail]).
class IncidentEvidenceSection extends StatelessWidget {
  static const Color _nameColor = Color(0xFF1E293B);
  static const Color _metaColor = Color(0xFF64748B);
  static const Color _downloadBg = Color(0xFFE8F6F5);

  static const List<_EvidenceAttachment> _files = [
    _EvidenceAttachment(
      extension: 'PDF',
      fileName: 'witness-statement.pdf',
      meta: '240 KB · PDF Document',
      badgeColor: Color(0xFFC0392B),
    ),
    _EvidenceAttachment(
      extension: 'JPG',
      fileName: 'common-area-photo.jpg',
      meta: '1.8 MB · Image',
      badgeColor: Color(0xFF3B6CC6),
    ),
    _EvidenceAttachment(
      extension: 'PNG',
      fileName: 'care-plan-note.png',
      meta: '512 KB · Image',
      badgeColor: Color(0xFF2E7D4F),
    ),
  ];

  const IncidentEvidenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('EVIDENCE & ATTACHMENTS'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        for (var i = 0; i < _files.length; i++) ...[
          if (i > 0) SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _EvidenceAttachmentCard(file: _files[i]),
        ],
      ],
    );
  }
}

class _EvidenceAttachment {
  final String extension;
  final String fileName;
  final String meta;
  final Color badgeColor;

  const _EvidenceAttachment({
    required this.extension,
    required this.fileName,
    required this.meta,
    required this.badgeColor,
  });
}

class _EvidenceAttachmentCard extends StatelessWidget {
  final _EvidenceAttachment file;

  const _EvidenceAttachmentCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final downloadSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: file.badgeColor,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              file.extension,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                color: Colors.white,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: IncidentEvidenceSection._nameColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  file.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: IncidentEvidenceSection._metaColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: downloadSize,
              height: downloadSize,
              decoration: BoxDecoration(
                color: IncidentEvidenceSection._downloadBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              alignment: Alignment.center,
              child: AppSvgIcon(
                'assets/icons/staff_incidents/download.svg',
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
