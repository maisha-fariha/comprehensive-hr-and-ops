import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../staff_core_constants.dart';

/// "Selfie Verification" row: bold title + a green "Verified · HH:MM"
/// subtitle, with a trailing circular photo thumbnail that has a small
/// green check badge overlaid on its corner.
///
/// NOTE: the thumbnail uses `StaffMaterialIconFallback.personAvatar`
/// (`Icons.person_rounded`) as a placeholder for the actual selfie photo —
/// see the feature's final report.
class SelfieVerificationRow extends StatelessWidget {
  final bool isVerified;
  final String verifiedLabel;

  const SelfieVerificationRow({super.key, required this.isVerified, required this.verifiedLabel});

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = ResponsiveHelper.getResponsiveSize(context, StaffDimens.selfieThumbnailSize);

    return SurfaceCard.card(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selfie Verification',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                Row(
                  children: [
                    const AppSvgIcon(AppAssets.checkCircle, size: 13, color: AppColors.activeGreen),
                    SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 5)),
                    Text(
                      isVerified ? verifiedLabel : 'Not verified',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.activeGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          SizedBox(
            width: thumbnailSize,
            height: thumbnailSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  decoration: const BoxDecoration(color: AppColors.dividerLight, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(
                    StaffMaterialIconFallback.personAvatar,
                    size: ResponsiveHelper.getResponsiveSize(context, 22),
                    color: AppColors.textFaint,
                  ),
                ),
                if (isVerified)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSize(context, 17),
                      height: ResponsiveHelper.getResponsiveSize(context, 17),
                      decoration: BoxDecoration(
                        color: AppColors.activeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceWhite, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const AppSvgIcon(AppAssets.checkCircle, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
