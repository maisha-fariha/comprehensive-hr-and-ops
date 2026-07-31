import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/missed_dose.dart';
import 'dose_note_box.dart';
import 'medication_route_row.dart';
import 'staff_medication_avatar.dart';
import 'status_by_row.dart';

/// A single card in the "Missed" tab's "Missed Doses" list: header row
/// (avatar/name/med + "SCHED. {time}" pill), a red "Missed by {name}"
/// status row and a "Reason: ..." note box.
class MissedDoseCard extends StatelessWidget {
  final MissedDose dose;

  const MissedDoseCard({super.key, required this.dose});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffMedicationAvatar(initials: dose.residentInitials, palette: dose.avatarColor),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dose.residentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                    Text(
                      '${dose.medicationName} ${dose.dose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                        color: AppColors.textBody,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                    MedicationRouteRow(route: dose.route),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              StatusBadge.chip(
                label: 'SCHED. ${dose.scheduledTimeLabel}',
                background: AppColors.criticalBackground,
                foreground: AppColors.criticalRed,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          StatusByRow(
            label: 'Missed',
            byName: dose.missedByName,
            background: AppColors.criticalBackground,
            foreground: AppColors.criticalRed,
            svgAsset: AppAssets.alertCircle,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          DoseNoteBox(
            label: 'Reason',
            text: dose.reason,
            background: AppColors.criticalBackgroundSoft,
          ),
        ],
      ),
    );
  }
}
