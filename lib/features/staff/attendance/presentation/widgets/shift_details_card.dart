import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import 'geofence_row.dart';
import 'time_worked_card.dart';

/// White "Shift Details" card: location header, nested timer, and geofence.
class ShiftDetailsCard extends StatelessWidget {
  final String locationName;
  final String timeRange;
  final String elapsedTimeLabel;
  final bool isWithinGeofence;
  final String geofenceAddress;
  final VoidCallback? onViewScheduleTap;
  final VoidCallback? onGeofenceTap;

  static const Color _primary = Color(0xFF1A2B3C);
  static const Color _secondary = Color(0xFF6A7C8A);
  static const Color _viewSchedule = Color(0xFF006D69);

  const ShiftDetailsCard({
    super.key,
    required this.locationName,
    required this.timeRange,
    required this.elapsedTimeLabel,
    required this.isWithinGeofence,
    required this.geofenceAddress,
    this.onViewScheduleTap,
    this.onGeofenceTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: _primary,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
                    Text(
                      timeRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                        color: _secondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              GestureDetector(
                onTap: onViewScheduleTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'View Schedule',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: _viewSchedule,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          TimeWorkedCard(elapsedTimeLabel: elapsedTimeLabel),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEF1F4)),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          GeofenceRow(
            isWithinGeofence: isWithinGeofence,
            address: geofenceAddress,
            onTap: onGeofenceTap,
            embedded: true,
          ),
        ],
      ),
    );
  }
}
