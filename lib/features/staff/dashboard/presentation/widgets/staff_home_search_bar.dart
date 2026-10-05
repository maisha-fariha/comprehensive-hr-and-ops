import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Staff Home search field — the web header "Search residents, staff,
/// tasks..." button, styled like the Manager dashboard search bar.
class StaffHomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const StaffHomeSearchBar({super.key, required this.onTap});

  static const String placeholder = 'Search residents, staff, tasks...';

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(
      context,
      AppDimens.searchBarHeight,
    );

    return Semantics(
      button: true,
      label: placeholder,
      child: GestureDetector(
        key: const Key('staff-home-search'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(height / 4),
            border: Border.all(color: AppColors.searchBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowTeal.withValues(alpha: 0.14),
                offset: Offset(
                  0,
                  ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
                blurRadius: ResponsiveHelper.getResponsiveHeight(context, 28),
              ),
            ],
          ),
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              const AppSvgIcon(
                AppAssets.search,
                size: 18,
                color: AppColors.textFaint,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13.5,
                    ),
                    color: AppColors.textPlaceholder,
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
