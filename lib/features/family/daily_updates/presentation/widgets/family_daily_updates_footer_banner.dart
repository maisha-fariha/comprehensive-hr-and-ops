import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Green-tinted rounded info banner shown at the bottom of the "Daily
/// Updates" screen reassuring the family that every entry is reviewed
/// before it becomes visible to them.
///
/// Icon note: no matching shield-check SVG exists in `assets/icons/*`, so
/// this uses `Icons.verified_user_rounded` as a temporary stand-in - flag
/// this for swapping to a real exported Figma asset later.
class FamilyDailyUpdatesFooterBanner extends StatelessWidget {
  final String message;

  const FamilyDailyUpdatesFooterBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.activeBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: ResponsiveHelper.getResponsiveSize(context, 18),
            color: AppColors.activeGreen,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.activeGreen,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
