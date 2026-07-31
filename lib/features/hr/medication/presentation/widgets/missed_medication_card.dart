import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/missed_medication.dart';
import 'medication_avatar.dart';

/// A single card in the "Missed" tab's "Missed Medications" list: header
/// row (avatar/name/med + Critical/Missed pills), a "SCHEDULED"/"MISSED"
/// two-column mini row, a "Review Medication Issue" link row and a
/// "Contact Staff" outlined button.
///
/// NOTE: the phone glyph on the "Contact Staff" button has no matching SVG
/// in `assets/icons/{dashboard,common,nav}` and the Figma asset-download
/// tool is unavailable this round, so [Icons.call_rounded] is used as a
/// placeholder.
class MissedMedicationCard extends StatelessWidget {
  final MissedMedication medication;
  final VoidCallback? onReviewTap;
  final VoidCallback? onContactStaffTap;

  const MissedMedicationCard({
    super.key,
    required this.medication,
    this.onReviewTap,
    this.onContactStaffTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MedicationAvatar(initials: medication.residentInitials, palette: medication.avatarColor),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      medication.residentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${medication.medicationName} ${medication.dose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (medication.isCritical) ...[
                    const StatusBadge.chip(
                      label: 'Critical',
                      background: AppColors.criticalRed,
                      foreground: Colors.white,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  ],
                  const StatusBadge.chip(
                    label: 'Missed',
                    background: AppColors.criticalBackgroundSoft,
                    foreground: AppColors.criticalRed,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Container(height: 1, color: AppColors.dividerLight),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniInfo(
                  caption: 'SCHEDULED',
                  value: medication.scheduledTime,
                  valueColor: AppColors.textBody,
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  caption: 'MISSED',
                  value: medication.missedTimeAgo,
                  valueColor: AppColors.criticalRed,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          GestureDetector(
            onTap: onReviewTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AppSvgIcon(AppAssets.alertTriangle, size: 14, color: AppColors.urgentAmber),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Text(
                  'Review Medication Issue',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          GestureDetector(
            onTap: onContactStaffTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.call_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 14),
                    color: AppColors.textBody,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                  Text(
                    'Contact Staff',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String caption;
  final String value;
  final Color valueColor;

  const _MiniInfo({required this.caption, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
