import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_appointment.dart';
import 'family_appointment_icon_style.dart';
import 'family_appointment_status_style.dart';

/// A single appointment row shown on the Family Appointments list, across
/// all 3 tabs ("All", "Upcoming", "Completed").
class FamilyAppointmentCard extends StatelessWidget {
  final FamilyAppointment appointment;

  const FamilyAppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final iconStyle = FamilyAppointmentIconStyle.of(appointment);
    final statusStyle = FamilyAppointmentStatusStyle.of(appointment.status);
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, 46);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: iconStyle.background,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 13),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(iconStyle.icon, size: ResponsiveHelper.getResponsiveSize(context, 21), color: iconStyle.color),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.dateTimeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.secondaryTealDark,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                    StatusBadge.pill(
                      label: statusStyle.label,
                      background: statusStyle.background,
                      foreground: statusStyle.foreground,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  appointment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                Row(
                  children: [
                    // Icon note: no pin/location-marker SVG exists in
                    // `assets/icons/*` yet, so this uses the Material
                    // `Icons.location_on_outlined` as a temporary stand-in.
                    Icon(Icons.location_on_outlined, size: ResponsiveHelper.getResponsiveSize(context, 14), color: AppColors.textFaint),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                    Expanded(
                      child: Text(
                        appointment.location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
