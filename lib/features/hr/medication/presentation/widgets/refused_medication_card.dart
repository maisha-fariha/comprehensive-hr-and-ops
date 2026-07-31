import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/refused_medication.dart';
import 'medication_avatar.dart';

/// A single card in the "Refused" tab's "Refused Medications" list: header
/// row, a "REASON" note box, a "REFUSED"/"REPORTED BY" two-column mini row
/// and a "Follow-up required" caption with a "Log follow-up →" link.
class RefusedMedicationCard extends StatelessWidget {
  final RefusedMedication medication;
  final VoidCallback? onLogFollowUpTap;

  const RefusedMedicationCard({super.key, required this.medication, this.onLogFollowUpTap});

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
              const StatusBadge.chip(
                label: 'Refused',
                background: AppColors.urgentBackground,
                foreground: AppColors.urgentAmber,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            children: [
              AppSvgIcon(AppAssets.messageCircle, size: 13, color: AppColors.textFaint),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                'REASON',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 9.5),
                  color: AppColors.textFaint,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.urgentBackgroundSoft,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 10)),
            ),
            child: Text(
              medication.reason,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textBody,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniInfoColumn(
                  caption: 'REFUSED',
                  child: Text(
                    medication.refusedTime,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _MiniInfoColumn(
                  caption: 'REPORTED BY',
                  child: Row(
                    children: [
                      MedicationAvatar(
                        initials: medication.reportedByInitials,
                        palette: medication.reportedByAvatarColor,
                        size: 18,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                      Flexible(
                        child: Text(
                          medication.reportedByName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (medication.needsFollowUp) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Container(height: 1, color: AppColors.dividerLight),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 7),
                      height: ResponsiveHelper.getResponsiveSize(context, 7),
                      decoration: const BoxDecoration(color: AppColors.urgentAmber, shape: BoxShape.circle),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 7)),
                    Text(
                      'Follow-up required',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.urgentAmber,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onLogFollowUpTap,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Log follow-up →',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniInfoColumn extends StatelessWidget {
  final String caption;
  final Widget child;

  const _MiniInfoColumn({required this.caption, required this.child});

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
        child,
      ],
    );
  }
}
