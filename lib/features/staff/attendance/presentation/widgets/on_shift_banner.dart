import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Green-tinted banner card: a check icon, "You are On Shift" and a
/// "Started at HH:MM" subtitle.
class OnShiftBanner extends StatelessWidget {
  final bool isOnShift;
  final String startedLabel;

  const OnShiftBanner({super.key, required this.isOnShift, required this.startedLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.activeBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusCard),
        ),
      ),
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 38),
            height: ResponsiveHelper.getResponsiveSize(context, 38),
            decoration: const BoxDecoration(color: AppColors.activeGreen, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const AppSvgIcon(AppAssets.checkCircle, size: 19, color: Colors.white),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOnShift ? 'You are On Shift' : 'You are Off Shift',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
              Text(
                startedLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.activeGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
