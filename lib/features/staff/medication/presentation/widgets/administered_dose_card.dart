import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/administered_dose.dart';
import 'medication_route_row.dart';
import 'staff_medication_avatar.dart';
import 'status_by_row.dart';

/// A single card in the "Administered" tab's "Administered Today" list:
/// header row (avatar/name/med + "GIVEN {time}" pill) plus a green
/// "Administered by {name}" status row.
class AdministeredDoseCard extends StatelessWidget {
  final AdministeredDose dose;

  const AdministeredDoseCard({super.key, required this.dose});

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
                label: 'GIVEN ${dose.givenTimeLabel}',
                background: AppColors.activeBackground,
                foreground: AppColors.activeGreen,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          StatusByRow(
            label: 'Administered',
            byName: dose.administeredByName,
            background: AppColors.activeBackground,
            foreground: AppColors.activeGreen,
            svgAsset: AppAssets.checkCircle,
          ),
        ],
      ),
    );
  }
}
