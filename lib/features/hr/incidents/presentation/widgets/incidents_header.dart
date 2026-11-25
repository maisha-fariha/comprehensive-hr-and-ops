import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../presentation/widgets/hr_company_brand.dart';

/// Incidents header: company brand (no hamburger), title, search.
class IncidentsHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const IncidentsHeader({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 42);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 8, bottom: 14),
      child: Row(
        children: [
          const Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: HrCompanyBrand(maxNameWidth: 110),
            ),
          ),
          Expanded(
            child: Text(
              'Incidents',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
