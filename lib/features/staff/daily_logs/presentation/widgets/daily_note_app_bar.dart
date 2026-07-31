import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';

/// Plain white top bar for the "Daily Note" screen: a back chevron, the
/// centered "Daily Note" title and a trailing teal "Save" text button.
///
/// Icon note: no matching back-chevron/save SVGs exist in `assets/icons/*`,
/// so this uses `Icons.arrow_back_ios_new_rounded` and
/// `Icons.save_outlined` as temporary stand-ins - flag these for swapping
/// to real exported Figma assets later.
class DailyNoteAppBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;

  const DailyNoteAppBar({super.key, this.onBack, this.onSave});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, top: 14, bottom: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? Get.back,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.textPrimary,
              ),
            ),
            Expanded(
              child: Text(
                'Daily Note',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSave,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_outlined,
                    size: ResponsiveHelper.getResponsiveSize(context, 15),
                    color: AppColors.secondaryTeal,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                  Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
