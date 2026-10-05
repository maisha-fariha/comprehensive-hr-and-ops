import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Plain white header: back + "My Schedule" + Filter + Create Shift
/// (BUG_Report004).
class StaffScheduleHeader extends StatelessWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onCreateShiftTap;

  const StaffScheduleHeader({
    super.key,
    this.onBackTap,
    this.onFilterTap,
    this.onCreateShiftTap,
  });

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
          child: Row(
            children: [
              GestureDetector(
                key: const Key('staff-schedule-back'),
                onTap: onBackTap,
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
              Expanded(
                child: Text(
                  'My Schedule',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
              ),
              GestureDetector(
                key: const Key('staff-schedule-filter'),
                onTap: onFilterTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  margin: EdgeInsets.only(
                    right: ResponsiveHelper.getResponsiveWidth(context, 8),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.filterButtonBackground,
                    borderRadius: BorderRadius.circular(buttonRadius),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: const AppSvgIcon(
                    AppAssets.filter,
                    size: 18,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (onCreateShiftTap != null)
                GestureDetector(
                  key: const Key('staff-schedule-create-shift'),
                  onTap: onCreateShiftTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 14),
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
                          width: ResponsiveHelper.getResponsiveWidth(context, 2),
                        ),
                        Text(
                          'Shift',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              12.5,
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
        ),
      ),
    );
  }
}
