import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// The plain white header for the "Profile & Settings" screen: a back
/// chevron and a centered title, matching the convention used by other
/// pushed, non-tabbed detail screens (see `StaffAttendanceHeader`).
///
/// The back chevron reuses the existing `AppAssets.chevronRight` SVG rotated
/// 180°, the same convention used across the HR/Staff portals, so no new
/// icon asset is needed.
class FamilyProfileSettingsHeader extends StatelessWidget {
  final VoidCallback? onBackTap;

  const FamilyProfileSettingsHeader({super.key, this.onBackTap});

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
                'Profile & Settings',
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
