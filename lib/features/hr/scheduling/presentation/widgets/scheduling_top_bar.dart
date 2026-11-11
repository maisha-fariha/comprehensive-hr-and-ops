import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../presentation/widgets/hr_company_brand.dart';
import '../../scheduling_constants.dart';

/// Scheduling top bar: company brand (no hamburger), optional actions, Create.
///
/// Narrow phones: brand name flexes/ellipsizes; secondary actions stay icon-only
/// so the row never RenderFlex-overflows.
class SchedulingTopBar extends StatelessWidget {
  final VoidCallback? onCreateShiftTap;
  final VoidCallback? onReviewRotaTap;
  final VoidCallback? onStaffHoursTap;

  const SchedulingTopBar({
    super.key,
    this.onCreateShiftTap,
    this.onReviewRotaTap,
    this.onStaffHoursTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Labels only when there is room after brand + Shift CTA.
    final labeledSecondaries = width >= 480 &&
        !(onReviewRotaTap != null && onStaffHoursTap != null && width < 560);

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: SchedulingDimens.screenPaddingHorizontal,
        top: 10,
        bottom: 12,
      ),
      child: Row(
        children: [
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: HrCompanyBrand(
                maxNameWidth: width < 380 ? 96 : 130,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
          if (onReviewRotaTap != null) ...[
            _OutlineAction(
              key: const ValueKey('scheduling-review-rota'),
              icon: Icons.auto_awesome,
              label: labeledSecondaries ? 'Review rota' : null,
              tooltip: 'Review rota',
              onTap: onReviewRotaTap!,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          ],
          if (onStaffHoursTap != null) ...[
            _OutlineAction(
              key: const ValueKey('scheduling-staff-hours'),
              icon: Icons.history_toggle_off_rounded,
              label: labeledSecondaries ? 'Staff Hours' : null,
              tooltip: 'Staff Hours',
              onTap: onStaffHoursTap!,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          ],
          if (onCreateShiftTap != null)
            GestureDetector(
              onTap: onCreateShiftTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: width < 360 ? 10 : 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(
                      context,
                      AppDimens.radiusButton,
                    ),
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
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 4),
                    ),
                    Text(
                      'Shift',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
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

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback onTap;

  const _OutlineAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: label == null ? 9 : 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(
            context,
            AppDimens.radiusButton,
          ),
        ),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.getResponsiveSize(context, 16),
            color: AppColors.primaryNavy,
          ),
          if (label != null) ...[
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
