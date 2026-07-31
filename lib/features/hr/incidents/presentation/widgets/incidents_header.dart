import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Top app bar for the Incidents screen: menu button, "Incidents" title and
/// a search button.
///
/// Icon note: the source Figma screenshot shows a hamburger-menu glyph with
/// no equivalent SVG in `assets/icons/*` yet, so this uses the built-in
/// Material `Icons.menu` as a temporary stand-in (flagged in the feature's
/// final report).
class IncidentsHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  const IncidentsHeader({super.key, this.onMenuTap, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 42);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
      child: Row(
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
          Expanded(
            child: Text(
              'Incidents',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 19),
                color: AppColors.textHeading,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSearchTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.searchBorder),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 13),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
