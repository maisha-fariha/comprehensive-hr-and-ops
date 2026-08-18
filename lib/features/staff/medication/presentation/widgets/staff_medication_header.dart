import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Flat white app-bar header for Medication MAR: bordered back chevron +
/// centered title, matching the header reference screenshot.
class StaffMedicationHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;

  const StaffMedicationHeader({super.key, required this.title, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    final backButton = GestureDetector(
      onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(buttonRadius),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: 3.14159,
          child: const AppSvgIcon(
            AppAssets.chevronRight,
            size: 18,
            color: AppColors.textHeading,
          ),
        ),
      ),
    );

    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 20,
            top: 8,
            bottom: 12,
          ),
          child: SizedBox(
            height: buttonSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                Align(alignment: Alignment.centerLeft, child: backButton),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
