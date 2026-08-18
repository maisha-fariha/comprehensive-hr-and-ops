import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../staff_core_constants.dart';

/// Selfie verification card with status line and thumbnail + badge.
class SelfieVerificationRow extends StatelessWidget {
  final bool isVerified;
  final String verifiedLabel;

  static const Color _primary = Color(0xFF1A2B3C);
  static const Color _verified = Color(0xFF2E7D32);
  static const Color _time = Color(0xFF707C8C);
  static const Color _avatarBg = Color(0xFFE2E8F0);

  const SelfieVerificationRow({
    super.key,
    required this.isVerified,
    required this.verifiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = ResponsiveHelper.getResponsiveSize(context, 54);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 20);
    final badgeSize = ResponsiveHelper.getResponsiveSize(context, 18);

    // "Verified · 7:02 AM" → green status + muted time.
    final parts = verifiedLabel.split(' · ');
    final statusText = isVerified
        ? (parts.isNotEmpty ? parts.first : 'Verified')
        : 'Not verified';
    final timeText =
        isVerified && parts.length > 1 ? parts.sublist(1).join(' · ') : null;

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selfie Verification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                    color: _primary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Row(
                  children: [
                    if (isVerified) ...[
                      const AppSvgIcon(
                        AppAssets.checkCircle,
                        size: 15,
                        color: _verified,
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                    ],
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: statusText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                color: isVerified ? _verified : AppColors.textMuted,
                              ),
                            ),
                            if (timeText != null)
                              TextSpan(
                                text: ' · $timeText',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w400,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                  color: _time,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  decoration: BoxDecoration(
                    color: _avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowNavy.withValues(alpha: 0.1),
                        offset: Offset(
                          0,
                          ResponsiveHelper.getResponsiveHeight(context, 2),
                        ),
                        blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    StaffMaterialIconFallback.personAvatar,
                    size: ResponsiveHelper.getResponsiveSize(context, 50),
                    color: AppColors.textFaint,
                  ),
                ),
                if (isVerified)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: _verified,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 10),
                        color: Colors.white,
                      ),
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
