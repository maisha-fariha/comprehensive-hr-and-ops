import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../staff_core_constants.dart';

/// Geofence status row. When [embedded] is true, renders without its own
/// card chrome (for use inside [ShiftDetailsCard]).
class GeofenceRow extends StatelessWidget {
  final bool isWithinGeofence;
  final String address;
  final VoidCallback? onTap;
  final bool embedded;

  static const Color _primary = Color(0xFF1A2B3C);
  static const Color _secondary = Color(0xFF6A7C8A);
  static const Color _iconBg = Color(0xFFEAF6F0);
  static const Color _iconFg = Color(0xFF2E8C58);

  const GeofenceRow({
    super.key,
    required this.isWithinGeofence,
    required this.address,
    this.onTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(
      context,
      StaffDimens.geofenceIconBoxSize,
    );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: const BoxDecoration(
            color: _iconBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check,
            size: 18,
            color: _iconFg,
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWithinGeofence ? 'Within Geofence' : 'Outside Geofence',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: _primary,
                  height: 1.2,
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
                  color: _secondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
        const AppSvgIcon(
          AppAssets.chevronRight,
          size: 16,
          color: AppColors.iconChevron,
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: embedded
          ? content
          : Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 14),
                ),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: content,
            ),
    );
  }
}
