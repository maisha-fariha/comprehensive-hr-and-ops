import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Plain white top bar for the Staff "Daily Logs" screen: a back chevron
/// and the centered "Daily Logs" title.
///
/// Icon note: no matching back-chevron SVG exists in `assets/icons/*`, so
/// this uses `Icons.arrow_back_ios_new_rounded` as a temporary stand-in -
/// flag this for swapping to a real exported Figma asset later.
class StaffDailyLogsAppBar extends StatelessWidget {
  final VoidCallback? onBack;

  const StaffDailyLogsAppBar({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 24);
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 14, bottom: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? Get.back,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.textPrimary,
              ),
            ),
            Expanded(
              child: Text(
                'Daily Logs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: buttonSize),
          ],
        ),
      ),
    );
  }
}
