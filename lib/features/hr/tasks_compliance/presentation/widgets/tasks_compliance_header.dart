import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header for Tasks & Compliance: menu, centered title/subtitle,
/// and a bordered search button — matched to the reference chrome.
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
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onMenuTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 7),
                  child: Icon(
                    Icons.menu_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 22),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tasks & Compliance',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: ResponsiveHelper.getResponsiveSize(context, 36),
                  height: ResponsiveHelper.getResponsiveSize(context, 36),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 10),
                    ),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(
                    AppAssets.search,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
