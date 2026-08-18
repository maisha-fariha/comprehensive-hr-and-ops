import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../attendance_assets.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/staff_status_entry.dart';
import 'attendance_avatar.dart';

class _StatusStyle {
  final Color background;
  final Color foreground;
  final String label;

  const _StatusStyle({required this.background, required this.foreground, required this.label});
}

const Map<StaffAttendanceStatus, _StatusStyle> _statusStyles = {
  StaffAttendanceStatus.onTime: _StatusStyle(
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
    label: 'On Time',
  ),
  StaffAttendanceStatus.late: _StatusStyle(
    background: AppColors.urgentBackground,
    foreground: AppColors.urgentAmber,
    label: 'Late',
  ),
  StaffAttendanceStatus.missed: _StatusStyle(
    background: AppColors.criticalBackground,
    foreground: AppColors.criticalRed,
    label: 'Missed',
  ),
};

/// A single row in the "Today" tab's "Staff Status" list.
class StaffStatusTile extends StatelessWidget {
  final StaffStatusEntry entry;
  final VoidCallback? onTap;

  const StaffStatusTile({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[entry.status]!;
    final isMissed = entry.status == StaffAttendanceStatus.missed;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AttendanceAvatar(
              initials: entry.initials,
              paletteIndex: entry.avatarPaletteIndex,
              showOnlineDot: !isMissed,
            ),
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
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMissed
                            ? AttendanceMaterialIconFallback.noClockIn
                            : AttendanceMaterialIconFallback.locationPin,
                        size: ResponsiveHelper.getResponsiveSize(context, 13),
                        color: isMissed ? AppColors.criticalRed : AppColors.textFaint,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                      Flexible(
                        child: Text(
                          entry.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge.pill(label: style.label, background: style.background, foreground: style.foreground),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                if (entry.timeLabel != null)
                  Text(
                    entry.timeLabel!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  Icon(
                    AttendanceMaterialIconFallback.overflowMenu,
                    size: ResponsiveHelper.getResponsiveSize(context, 16),
                    color: AppColors.textFaint,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
