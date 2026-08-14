import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/family_profile.dart';
import '../../family_profile_settings_constants.dart';
import 'family_initials_avatar.dart';

/// The tappable profile card at the top of the "Profile & Settings" screen:
/// peach initials avatar, name, teal relationship, muted email, trailing chevron.
class FamilyProfileCard extends StatelessWidget {
  final FamilyProfile profile;
  final VoidCallback? onTap;

  static const Color _nameColor = Color(0xFF1A2B48);
  static const Color _relationshipColor = Color(0xFF2D7D72);
  static const Color _emailColor = Color(0xFF6B7C93);
  static const Color _chevronColor = Color(0xFFC5CCD6);
  static const Color _cardBorder = Color(0xFFEEF1F4);
  static const Color _shadow = Color(0xFF142846);

  const FamilyProfileCard({super.key, required this.profile, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: _shadow.withValues(alpha: 0.04),
              offset: Offset(
                0,
                ResponsiveHelper.getResponsiveHeight(context, 1),
              ),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 2),
            ),
            BoxShadow(
              color: _shadow.withValues(alpha: 0.05),
              offset: Offset(
                0,
                ResponsiveHelper.getResponsiveHeight(context, 6),
              ),
              blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            FamilyInitialsAvatar(
              initials: profile.initials,
              size: 50,
              background:
                  FamilyProfileSettingsConstants.profileAvatarBackground,
              foreground:
                  FamilyProfileSettingsConstants.profileAvatarForeground,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        16.5,
                      ),
                      color: _nameColor,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveHeight(context, 2),
                  ),
                  Text(
                    profile.relationship,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        13,
                      ),
                      color: _relationshipColor,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        13,
                      ),
                      color: _emailColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            const AppSvgIcon(
              AppAssets.chevronRight,
              size: 18,
              color: _chevronColor,
            ),
          ],
        ),
      ),
    );
  }
}
