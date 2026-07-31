import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../staff_core_constants.dart';

/// Full-width red-tinted alert row: a warning-triangle icon, a large red
/// count and an "Alerts" label, with a red left accent bar — reusing the
/// HR Manager Dashboard's `NeedsAttentionCard`/alert-tile visual language
/// (critical-red palette + `alertTriangle` icon).
class StaffAlertsBanner extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const StaffAlertsBanner({super.key, required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 18),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.criticalBackgroundSoft,
            border: Border(left: BorderSide(color: AppColors.criticalRed, width: StaffDimens.alertAccentBarWidth)),
          ),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 17, vertical: 15),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 40),
                height: ResponsiveHelper.getResponsiveSize(context, 40),
                decoration: BoxDecoration(
                  color: AppColors.criticalBackground,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: const AppSvgIcon(AppAssets.alertTriangle, size: 20, color: AppColors.criticalRed),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 14)),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, StaffDimens.alertNumberFontSize),
                  color: AppColors.criticalRed,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
