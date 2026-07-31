import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../domain/entities/calendar_schedule.dart';
import '../../scheduling_constants.dart';
import 'calendar_month_header.dart';
import 'calendar_shift_card.dart';
import 'calendar_week_strip.dart';

/// The Calendar tab's content: a fixed month strip (month navigator + the
/// selectable week of days) above a scrollable daily agenda of shift cards.
class CalendarTabView extends StatelessWidget {
  final CalendarSchedule data;

  const CalendarTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.surfaceWhite,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            ResponsiveHelper.getResponsiveHeight(context, 18),
          ),
          child: Column(
            children: [
              CalendarMonthHeader(monthLabel: data.monthLabel),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
              CalendarWeekStrip(days: data.days),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.scaffoldBackground,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                ResponsiveHelper.getResponsiveHeight(context, 18),
                horizontalPadding,
                ResponsiveHelper.getResponsiveHeight(context, 24),
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.selectedDateLabel,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              color: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                          Text(
                            data.shiftsSummaryLabel,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.pill(
                      label: data.openShiftsLabel,
                      background: AppColors.urgentBackground,
                      foreground: AppColors.urgentAmber,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                for (final shift in data.shifts) CalendarShiftCard(shift: shift),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
