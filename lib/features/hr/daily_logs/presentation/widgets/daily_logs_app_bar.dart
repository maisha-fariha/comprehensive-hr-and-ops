import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Plain white top bar for the Daily Logs screen: a menu icon, the "Daily
/// Logs" title and a search icon.
///
/// NOTE: no matching SVG exists in `assets/icons/*` for a hamburger/menu
/// glyph, so this uses `Icons.menu_rounded` as a temporary stand-in - flag
/// this for swapping to a real exported Figma asset later.
class DailyLogsAppBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  const DailyLogsAppBar({super.key, this.onMenuTap, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 14, bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onMenuTap,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.menu_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 24),
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Daily Logs',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: const AppSvgIcon(AppAssets.search, size: 20, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
