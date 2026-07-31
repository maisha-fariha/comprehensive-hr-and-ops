import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// The plain white header shared by non-tabbed Staff screens: a back
/// chevron and a centered title.
///
/// The back chevron reuses the existing `AppAssets.chevronRight` SVG
/// rotated 180° (the same convention as the HR Scheduling feature's
/// `SchedulingAssets.monthChevron`), so no new/Material icon is needed.
class StaffAttendanceHeader extends StatelessWidget {
  final VoidCallback? onBackTap;

  const StaffAttendanceHeader({super.key, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final buttonBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxMedium);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: buttonBoxSize,
              height: buttonBoxSize,
              child: Transform.rotate(
                angle: 3.14159,
                child: const AppSvgIcon(AppAssets.chevronRight, size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Attendance',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17.5),
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ),
          SizedBox(width: buttonBoxSize),
        ],
      ),
    );
  }
}
