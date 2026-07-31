import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Plain white top bar for the "Daily Updates" screen: a back chevron, the
/// "Daily Updates" title with a small caption beneath it, and a trailing
/// filter icon button.
///
/// Icon note: no matching back-chevron SVG exists in `assets/icons/*`, so
/// this uses `Icons.arrow_back_ios_new_rounded` as a temporary stand-in -
/// flag this for swapping to a real exported Figma asset later.
class FamilyDailyUpdatesAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;

  const FamilyDailyUpdatesAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 14, bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            GestureDetector(
              onTap: onFilterTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ResponsiveHelper.getResponsiveSize(context, 38),
                height: ResponsiveHelper.getResponsiveSize(context, 38),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 11),
                  ),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(AppAssets.filter, size: 17, color: AppColors.secondaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
