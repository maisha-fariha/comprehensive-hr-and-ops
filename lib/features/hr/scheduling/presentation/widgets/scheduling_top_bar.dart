import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../scheduling_constants.dart';

/// The Scheduling screen's top bar: a menu button, the "Schedule" title and
/// a "+ Shift" quick-create button. Shared by all 3 segmented tabs
/// (Calendar / Board / Requests).
///
/// NOTE: the menu glyph and the "+" glyph are rendered with Material Icons
/// (`Icons.menu_rounded` / `Icons.add_rounded`) as temporary stand-ins —
/// see the feature's final report for why no matching SVG could be
/// exported from Figma for this build.
class SchedulingTopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onCreateShiftTap;

  const SchedulingTopBar({super.key, this.onMenuTap, this.onCreateShiftTap});

  @override
  Widget build(BuildContext context) {
    final buttonBoxSize = ResponsiveHelper.getResponsiveSize(context, AppDimens.iconBoxMedium);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: SchedulingDimens.screenPaddingHorizontal,
        top: 10,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: buttonBoxSize,
              height: buttonBoxSize,
              child: Icon(
                Icons.menu_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, AppDimens.iconNav),
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Schedule',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                  color: AppColors.textHeading,
                  height: 23 / 17,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCreateShiftTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, AppDimens.radiusButton),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: ResponsiveHelper.getResponsiveSize(context, 16),
                    color: Colors.white,
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                  Text(
                    'Shift',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
