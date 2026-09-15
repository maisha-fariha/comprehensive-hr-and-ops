import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../domain/entities/incident_evidence_item.dart';
import 'section_label.dart';

/// "EVIDENCE & ATTACHMENTS" section on Incident Details.
class IncidentEvidenceSection extends StatelessWidget {
  static const Color _nameColor = Color(0xFF1E293B);
  static const Color _metaColor = Color(0xFF64748B);
  static const Color _downloadBg = Color(0xFFE8F6F5);

  final List<IncidentEvidenceItem> items;
  final ValueChanged<IncidentEvidenceItem>? onDownload;
  final bool isBusy;

  const IncidentEvidenceSection({
    super.key,
    required this.items,
    this.onDownload,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IncidentDetailsSectionLabel('EVIDENCE & ATTACHMENTS'),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
        if (items.isEmpty)
          Text(
            'No evidence attached.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: _metaColor,
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            _EvidenceAttachmentCard(
              item: items[i],
              onDownload: isBusy ? null : onDownload,
            ),
          ],
      ],
    );
  }
}

class _EvidenceAttachmentCard extends StatelessWidget {
  final IncidentEvidenceItem item;
  final ValueChanged<IncidentEvidenceItem>? onDownload;

  const _EvidenceAttachmentCard({
    required this.item,
    this.onDownload,
  });

  Color get _badgeColor {
    switch (item.extensionLabel) {
      case 'PDF':
        return const Color(0xFFC0392B);
      case 'PNG':
        return const Color(0xFF2E7D4F);
      case 'JPG':
      case 'JPEG':
        return const Color(0xFF3B6CC6);
      default:
        return AppColors.secondaryTeal;
    }
  }

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
              color: _badgeColor,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.extensionLabel,
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
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: IncidentEvidenceSection._nameColor,
                    height: 1.25,
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 3),
                ),
                Text(
                  item.metaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: IncidentEvidenceSection._metaColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          GestureDetector(
            onTap: onDownload == null ? null : () => onDownload!(item),
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
