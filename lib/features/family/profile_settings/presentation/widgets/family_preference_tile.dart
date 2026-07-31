import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_preference_item.dart';
import '../../family_profile_settings_constants.dart';

/// A single row in the "Preferences & Support" section: icon-in-box, a bold
/// label, and a trailing chevron. Unlike `StaffMenuTile`/`_MoreMenuTile`
/// this has no subtitle line, matching the reference screenshot.
class FamilyPreferenceTile extends StatelessWidget {
  final FamilyPreferenceItem item;
  final VoidCallback? onTap;

  const FamilyPreferenceTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxMedium);
    final icon = FamilyProfileSettingsConstants.preferenceIcon(item.type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: FamilyProfileSettingsConstants.preferenceIconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
                ),
              ),
              alignment: Alignment.center,
              child: icon.svgAsset != null
                  ? AppSvgIcon(
                      icon.svgAsset!,
                      size: AppDimens.iconRegular,
                      color: FamilyProfileSettingsConstants.preferenceIconForeground,
                    )
                  : Icon(
                      icon.materialIcon,
                      size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconRegular),
                      color: FamilyProfileSettingsConstants.preferenceIconForeground,
                    ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconMedium),
              color: AppColors.iconChevron,
            ),
          ],
        ),
      ),
    );
  }
}
