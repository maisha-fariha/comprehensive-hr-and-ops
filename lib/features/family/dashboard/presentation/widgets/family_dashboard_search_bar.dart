import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Floating pill search field centered on the teal header / body seam.
class FamilyDashboardSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  static const Color _filterBg = Color(0xFFE8F3F2);
  static const Color _filterIcon = Color(0xFF5A6B78);

  const FamilyDashboardSearchBar({super.key, this.onTap, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(context, AppDimens.searchBarHeight);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final filterSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: height,
          padding: ResponsiveHelper.getResponsivePadding(context, left: 16, right: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.searchBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowTeal.withValues(alpha: 0.12),
                offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 10)),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 24),
              ),
            ],
          ),
          child: Row(
            children: [
              const AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textFaint),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Text(
                  'Search updates, visits, or messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              GestureDetector(
                onTap: onFilterTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: filterSize,
                  height: filterSize,
                  decoration: BoxDecoration(
                    color: _filterBg,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(AppAssets.filter, size: 16, color: _filterIcon),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
