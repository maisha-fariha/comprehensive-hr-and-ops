import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/surface_card.dart';

/// The destructive "Log Out" row at the very bottom of the "Profile &
/// Settings" screen — the minimal, plausible completion of the cropped
/// "App Settings" section (see `FamilyProfileSettingsOverview`), styled to
/// match the icon-box + label row pattern used by the rest of the page but
/// in red/destructive tones.
class FamilyLogOutRow extends StatelessWidget {
  final VoidCallback? onTap;

  const FamilyLogOutRow({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxMedium);

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
                color: AppColors.criticalBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusIconBoxMedium),
                ),
              ),
              alignment: Alignment.center,
              // No existing SVG matches a "log out" glyph and the Figma
              // asset-download tool is unavailable this round (monthly
              // quota exhausted), so this uses Material
              // `Icons.logout_rounded` as a temporary stand-in.
              child: Icon(
                Icons.logout_rounded,
                size: ResponsiveHelper.getResponsiveFontSize(context, AppDimens.iconRegular),
                color: AppColors.criticalRed,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: AppColors.criticalRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
