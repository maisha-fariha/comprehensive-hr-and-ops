import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header shared by all 3 "Tasks & Compliance" tabs: a menu button,
/// the screen title + subtitle, and a search button.
class TasksComplianceHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;

  const TasksComplianceHeader({
    super.key,
    required this.subtitle,
    this.onMenuTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 6, bottom: 14),
      child: Row(
        children: [
          // No hamburger-menu SVG exists in the shared icon set, so this
          // falls back to the closest Material icon.
          _IconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tasks & Compliance',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          _IconButton(svgAsset: AppAssets.search, onTap: onSearchTap),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback? onTap;

  const _IconButton({this.icon, this.svgAsset, this.onTap}) : assert(icon != null || svgAsset != null);

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 40);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 12)),
        ),
        alignment: Alignment.center,
        child: svgAsset != null
            ? AppSvgIcon(svgAsset!, size: 17, color: AppColors.textHeading)
            : Icon(icon, size: ResponsiveHelper.getResponsiveSize(context, 20), color: AppColors.textHeading),
      ),
    );
  }
}
