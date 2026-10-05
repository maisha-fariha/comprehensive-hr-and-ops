import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';

/// Attendance header with back + Clock in + Manual Entry (web parity).
class StaffAttendanceHeader extends StatelessWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onClockInTap;
  final VoidCallback? onClockOutTap;
  final VoidCallback? onManualEntryTap;
  final bool isOnShift;

  const StaffAttendanceHeader({
    super.key,
    this.onBackTap,
    this.onClockInTap,
    this.onClockOutTap,
    this.onManualEntryTap,
    this.isOnShift = false,
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
        child: Column(
          children: [
            SizedBox(
              height: buttonSize,
              child: Row(
                children: [
                  GestureDetector(
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
                      'Attendance',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          18,
                        ),
                        color: AppColors.textHeading,
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(width: buttonSize),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: Key(
                      isOnShift
                          ? 'staff-attendance-clock-out'
                          : 'staff-attendance-clock-in',
                    ),
                    onTap: isOnShift ? onClockOutTap : onClockInTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 14),
                        ),
                        border: Border.all(
                          color: isOnShift
                              ? AppColors.criticalRed
                              : AppColors.activeGreen,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOnShift
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                            size: 16,
                            color: isOnShift
                                ? AppColors.criticalRed
                                : AppColors.activeGreen,
                          ),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(
                              context,
                              6,
                            ),
                          ),
                          Text(
                            isOnShift ? 'Clock out' : 'Clock in',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              color: isOnShift
                                  ? AppColors.criticalRed
                                  : AppColors.activeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Expanded(
                  child: GestureDetector(
                    key: const Key('staff-attendance-manual-entry'),
                    onTap: onManualEntryTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal,
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveRadius(context, 14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(
                              context,
                              4,
                            ),
                          ),
                          Text(
                            'Manual Entry',
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
