import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/surface_card.dart';

/// A single navigable entry shown on the Family "More" hub page — icon,
/// title and subtitle.
class FamilyMenuEntry {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  const FamilyMenuEntry({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class FamilyMenuTile extends StatelessWidget {
  final FamilyMenuEntry entry;
  final VoidCallback onTap;

  const FamilyMenuTile({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveWidth(
                context,
                AppDimens.iconBoxMedium,
              ),
              height: ResponsiveHelper.getResponsiveHeight(
                context,
                AppDimens.iconBoxMedium,
              ),
              decoration: BoxDecoration(
                color: entry.iconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(
                    context,
                    AppDimens.radiusIconBoxMedium,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.icon,
                size: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  AppDimens.iconMedium,
                ),
                color: entry.iconColor,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14.5,
                      ),
                      fontWeight: AppFontWeight.semiBold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 2),
                  ),
                  Text(
                    entry.subtitle,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        12,
                      ),
                      fontWeight: AppFontWeight.regular,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: ResponsiveHelper.getResponsiveFontSize(
                context,
                AppDimens.iconMedium,
              ),
              color: AppColors.iconChevron,
            ),
          ],
        ),
      ),
    );
  }
}
