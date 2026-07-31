import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../attendance_assets.dart';
import '../../domain/entities/late_arrival_entry.dart';
import 'attendance_avatar.dart';

/// A single card in the "Late" tab's "Late Arrivals" list.
class LateArrivalCard extends StatelessWidget {
  final LateArrivalEntry entry;
  final VoidCallback? onTap;

  const LateArrivalCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AttendanceAvatar(initials: initialsFromName(entry.name), paletteIndex: entry.avatarPaletteIndex),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 11)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        entry.role,
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
                StatusBadge.pill(
                  label: entry.lateLabel,
                  background: AppColors.urgentBackground,
                  foreground: AppColors.urgentAmber,
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 13)),
            Row(
              children: [
                Expanded(
                  child: _LabeledValue(label: 'SCHEDULED', value: entry.scheduledRange),
                ),
                Expanded(
                  child: _LabeledValue(
                    label: 'CLOCKED IN',
                    value: entry.clockedInTime,
                    valueColor: AppColors.urgentAmber,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 11)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AttendanceMaterialIconFallback.locationPin,
                  size: ResponsiveHelper.getResponsiveSize(context, 13),
                  color: AppColors.textFaint,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                Text(
                  entry.distanceLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _LabeledValue({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
            color: AppColors.textFaint,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
