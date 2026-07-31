import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../staff_core_constants.dart';

/// "Within Geofence" row: a green check icon, bold title, an address
/// subtitle and a trailing disclosure chevron.
class GeofenceRow extends StatelessWidget {
  final bool isWithinGeofence;
  final String address;
  final VoidCallback? onTap;

  const GeofenceRow({super.key, required this.isWithinGeofence, required this.address, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSize(context, StaffDimens.geofenceIconBoxSize),
              height: ResponsiveHelper.getResponsiveSize(context, StaffDimens.geofenceIconBoxSize),
              decoration: BoxDecoration(
                color: AppColors.activeIconBackground,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 11),
                ),
              ),
              alignment: Alignment.center,
              child: const AppSvgIcon(AppAssets.checkCircle, size: 18, color: AppColors.activeGreen),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWithinGeofence ? 'Within Geofence' : 'Outside Geofence',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            const AppSvgIcon(AppAssets.chevronRight, size: 16, color: AppColors.iconChevron),
          ],
        ),
      ),
    );
  }
}
