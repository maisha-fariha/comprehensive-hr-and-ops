import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// White header: bordered back button, centered "Daily Note", trailing teal
/// "Save" — matches Schedule / Daily Logs / Attendance headers.
class DailyNoteAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const DailyNoteAppBar({super.key, this.onBack, this.onSave});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 40);
    final buttonRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return ColoredBox(
      color: AppColors.surfaceWhite,
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
                'Daily Note',
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
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack ?? Get.back,
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
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onSave,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        color: AppColors.secondaryTeal,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
