import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../attendance_constants.dart';

/// Derives 1-2 letter initials from a full name, e.g. "Mike T." -> "MT".
String initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

/// Circular initials avatar reused across every Attendance list row/card,
/// with an optional small "online" indicator dot (shown on non-missed rows
/// in the "Today" tab's Staff Status list).
class AttendanceAvatar extends StatelessWidget {
  final String initials;
  final int paletteIndex;
  final bool showOnlineDot;
  final double size;

  const AttendanceAvatar({
    super.key,
    required this.initials,
    required this.paletteIndex,
    this.showOnlineDot = false,
    this.size = AttendanceDimens.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = attendanceAvatarPalette[paletteIndex % attendanceAvatarPalette.length];
    final resolvedSize = ResponsiveHelper.getResponsiveSize(context, size);

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: resolvedSize,
            height: resolvedSize,
            decoration: BoxDecoration(color: palette.background, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: palette.foreground,
              ),
            ),
          ),
          if (showOnlineDot)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: ResponsiveHelper.getResponsiveSize(context, 11),
                height: ResponsiveHelper.getResponsiveSize(context, 11),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceWhite, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
