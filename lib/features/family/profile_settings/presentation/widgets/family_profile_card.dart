import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/family_profile.dart';
import '../../family_profile_settings_constants.dart';
import 'family_initials_avatar.dart';

/// The tappable profile card at the top of the "Profile & Settings" screen:
/// avatar, name, relationship + email, and a trailing chevron to edit the
/// profile.
class FamilyProfileCard extends StatelessWidget {
  final FamilyProfile profile;
  final VoidCallback? onTap;

  const FamilyProfileCard({super.key, required this.profile, this.onTap});

  @override
  Widget build(BuildContext context) {
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
            FamilyInitialsAvatar(
              initials: profile.initials,
              background: FamilyProfileSettingsConstants.profileAvatarBackground,
              foreground: FamilyProfileSettingsConstants.profileAvatarForeground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                      color: AppColors.textHeading,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  Text(
                    profile.relationship,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
