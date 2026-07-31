import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../scheduling_assets.dart';
import '../../scheduling_constants.dart';
import 'coverage_status_style.dart';
import 'staff_avatar_circle.dart';

/// A single shift row in the Calendar tab's daily timeline: a time-rail
/// (start time + a dot connected to the next row by a vertical divider) and
/// a card showing the shift's name, time range, staff-fill progress bar,
/// facepile and (optionally) its remaining open positions.
class CalendarShiftCard extends StatelessWidget {
  final CalendarShift shift;
  final VoidCallback? onTap;

  const CalendarShiftCard({super.key, required this.shift, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = coverageStatusStyles[shift.status]!;
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 10);

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveHeight(context, 16)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: ResponsiveHelper.getResponsiveWidth(context, 44),
              child: Column(
                children: [
                  Text(
                    shift.startTime,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    shift.startPeriod,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
                  ),
                  if (shift.showTimelineDivider)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveHeight(context, 6)),
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
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: SurfaceCard.card(
                  padding: ResponsiveHelper.getResponsivePadding(context, all: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shift.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dividerLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${shift.filled} / ${shift.total}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                      Text(
                        shift.timeRange,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(context, SchedulingDimens.progressBarHeight),
                          child: Stack(
                            children: [
                              Container(color: AppColors.dividerLight),
                              FractionallySizedBox(
                                widthFactor: (shift.filled / shift.total).clamp(0, 1),
                                child: Container(color: style.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < shift.avatars.length; i++)
                                StaffAvatarCircle(
                                  avatar: shift.avatars[i],
                                  size: SchedulingDimens.calendarAvatarSize,
                                  isFirst: i == 0,
                                ),
                            ],
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                          Expanded(
                            child: Text(
                              shift.namesSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (shift.openPositionsLabel != null) ...[
                            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                            AppSvgIcon(SchedulingAssets.openPositionWarning, size: 12, color: style.accent),
                            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 3)),
                            Text(
                              shift.openPositionsLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                                color: style.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
