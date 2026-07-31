import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../attendance_assets.dart';
import '../../attendance_constants.dart';

/// The plain white header shared by every Attendance tab: a hamburger menu
/// button, the centered "Attendance" title and a bordered calendar button.
class AttendanceHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onCalendarTap;

  const AttendanceHeader({super.key, this.onMenuTap, this.onCalendarTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              AttendanceMaterialIconFallback.menu,
              size: ResponsiveHelper.getResponsiveSize(context, 24),
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              'Attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17.5),
                color: AppColors.textHeading,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCalendarTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, AttendanceDimens.headerIconButtonSize),
              height: ResponsiveHelper.getResponsiveSize(context, AttendanceDimens.headerIconButtonSize),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 11),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AttendanceAssets.calendar, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
