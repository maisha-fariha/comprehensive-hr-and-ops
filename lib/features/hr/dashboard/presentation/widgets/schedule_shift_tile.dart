import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/dashboard_enums.dart';
import '../../domain/entities/schedule_shift.dart';

class _ShiftPeriodStyle {
  final Color indicatorColor;
  final Color badgeBackground;
  final Color badgeColor;

  const _ShiftPeriodStyle({
    required this.indicatorColor,
    required this.badgeBackground,
    required this.badgeColor,
  });
}

const Map<ShiftPeriod, _ShiftPeriodStyle> _shiftStyles = {
  ShiftPeriod.morning: _ShiftPeriodStyle(
    indicatorColor: AppColors.morningIndicator,
    badgeBackground: AppColors.activeBackground,
    badgeColor: AppColors.activeGreen,
  ),
  ShiftPeriod.evening: _ShiftPeriodStyle(
    indicatorColor: AppColors.eveningIndicator,
    badgeBackground: AppColors.urgentBackground,
    badgeColor: AppColors.urgentAmber,
  ),
  ShiftPeriod.night: _ShiftPeriodStyle(
    indicatorColor: AppColors.nightIndicator,
    badgeBackground: AppColors.nightBackground,
    badgeColor: AppColors.nightPurple,
  ),
};

/// A single row in the "Today's Schedule" timeline: a colored dot connected
/// by a vertical divider to the next row, the shift name/time and a staff
/// count pill.
class ScheduleShiftTile extends StatelessWidget {
  final ScheduleShift shift;

  const ScheduleShiftTile({super.key, required this.shift});

  @override
  Widget build(BuildContext context) {
    final style = _shiftStyles[shift.period]!;
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 11);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 16),
            child: Column(
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  margin: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
                  decoration: BoxDecoration(color: style.indicatorColor, shape: BoxShape.circle),
                ),
                if (shift.showTimelineDivider)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      child: Center(
                        child: Container(width: 2, color: AppColors.timelineDivider),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shift.name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          shift.timeRange,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSize(context, 6),
                          height: ResponsiveHelper.getResponsiveSize(context, 6),
                          decoration: BoxDecoration(color: style.badgeColor, shape: BoxShape.circle),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                        Text(
                          '${shift.staffCount}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: style.badgeColor,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 2)),
                        Text(
                          'Staff',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: style.badgeColor,
                          ),
                        ),
                      ],
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
