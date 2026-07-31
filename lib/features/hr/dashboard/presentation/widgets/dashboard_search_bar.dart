import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Floating search field that visually overlaps the boundary between the
/// gradient header and the scrollable content below it.
class DashboardSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  const DashboardSearchBar({super.key, this.onTap, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(context, 52);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Material(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 16),
            ),
            elevation: 0,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 16),
              ),
              child: Container(
                height: height,
                padding: ResponsiveHelper.getResponsivePadding(context, left: 47, right: 53),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 16),
                  ),
                  border: Border.all(color: AppColors.searchBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowTeal.withValues(alpha: 0.14),
                      offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 12)),
                      blurRadius: ResponsiveHelper.getResponsiveHeight(context, 28),
                    ),
                  ],
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search clients, documents, or medical records…',
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
            ),
          ),
          Positioned(
            left: ResponsiveHelper.getResponsiveWidth(context, 16),
            top: 0,
            bottom: 0,
            child: const Center(
              child: AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textFaint),
            ),
          ),
          Positioned(
            right: ResponsiveHelper.getResponsiveWidth(context, 8),
            top: ResponsiveHelper.getResponsiveHeight(context, 7),
            bottom: ResponsiveHelper.getResponsiveHeight(context, 7),
            child: GestureDetector(
              onTap: onFilterTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ResponsiveHelper.getResponsiveSize(context, 38),
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
          ),
        ],
      ),
    );
  }
}
