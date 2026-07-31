import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../staff_core_constants.dart';

/// Full-width outlined red button pinned near the bottom of the screen.
///
/// NOTE: the leading arrow glyph has no matching exported SVG yet, so
/// `StaffMaterialIconFallback.clockOutArrow` stands in for it — see the
/// feature's final report.
class ClockOutButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ClockOutButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.criticalRed),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              StaffMaterialIconFallback.clockOutArrow,
              size: ResponsiveHelper.getResponsiveSize(context, 17),
              color: AppColors.criticalRed,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Text(
              'Clock Out',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                color: AppColors.criticalRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
