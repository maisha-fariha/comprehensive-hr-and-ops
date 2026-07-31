import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/refused_dose.dart';
import 'dose_note_box.dart';
import 'medication_route_row.dart';
import 'staff_medication_avatar.dart';
import 'status_by_row.dart';

/// A single card in the "Refused" tab's "Refused by Client" list: header
/// row (avatar/name/med + "TIME {time}" pill), an amber "Refused by {name}"
/// status row and a "Notes: ..." note box.
///
/// NOTE: there is no existing SVG with an amber "refused"/"blocked" glyph
/// in `assets/icons/{dashboard,common,nav}`, and the Figma asset-download
/// tool is unavailable this round, so `Icons.block_rounded` is used as a
/// placeholder — matching the same precedent already established by the HR
/// Medication feature's `medication_stat_tile.dart` for its refused-related
/// stat tags.
class RefusedDoseCard extends StatelessWidget {
  final RefusedDose dose;

  const RefusedDoseCard({super.key, required this.dose});

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
                label: 'TIME ${dose.timeLabel}',
                background: AppColors.urgentBackground,
                foreground: AppColors.urgentAmber,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          StatusByRow(
            label: 'Refused',
            byName: dose.refusedByName,
            background: AppColors.urgentBackground,
            foreground: AppColors.urgentAmber,
            materialIcon: Icons.block_rounded,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          DoseNoteBox(
            label: 'Notes',
            text: dose.notes,
            background: AppColors.urgentBackgroundSoft,
          ),
        ],
      ),
    );
  }
}
