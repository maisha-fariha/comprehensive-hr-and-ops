import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/calendar_schedule.dart';
import '../../domain/entities/calendar_shift.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../../domain/entities/staff_avatar.dart';
import '../../scheduling_constants.dart';

/// The Calendar tab's content: month navigator, week strip, and the daily
/// agenda of timeline shift cards — matched to the Figma reference.
class CalendarTabView extends StatelessWidget {
  final CalendarSchedule data;

  const CalendarTabView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final horizontalPad = ResponsiveHelper.getResponsiveWidth(
      context,
      SchedulingDimens.screenPaddingHorizontal,
    );

    return ColoredBox(
      color: AppColors.scaffoldBackground,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getResponsiveHeight(context, 24),
        ),
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                ResponsiveHelper.getResponsiveHeight(context, 6),
                horizontalPad,
                ResponsiveHelper.getResponsiveHeight(context, 14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthHeader(monthLabel: data.monthLabel),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                  _WeekStrip(days: data.days),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              ResponsiveHelper.getResponsiveHeight(context, 18),
              horizontalPad,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DaySummaryHeader(
                  dateLabel: data.selectedDateLabel,
                  summaryLabel: data.shiftsSummaryLabel,
                  openLabel: data.openShiftsLabel,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                for (var i = 0; i < data.shifts.length; i++)
                  _ShiftTimelineRow(
                    shift: data.shifts[i],
                    isLast: i == data.shifts.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month header
// ─────────────────────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  final String monthLabel;

  const _MonthHeader({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Row(
      children: [
        Expanded(
          child: Text(
            monthLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              color: AppColors.textHeading,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _MonthNavButton(size: buttonSize, rotated: true),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        _MonthNavButton(size: buttonSize, rotated: false),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final double size;
  final bool rotated;

  const _MonthNavButton({required this.size, required this.rotated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotated ? math.pi : 0,
        child: const AppSvgIcon(
          AppAssets.chevronRight,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week strip
// ─────────────────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  final List<CalendarDay> days;

  const _WeekStrip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) Expanded(child: _DayCell(day: day)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final CalendarDay day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final isSelected = day.isSelected;
    final isIndicator = day.hasShiftIndicator && !isSelected;

    final dayLabelColor = isSelected
        ? Colors.white
        : isIndicator
            ? AppColors.secondaryTeal
            : AppColors.textFaint;

    final dayNumberColor = isSelected
        ? Colors.white
        : isIndicator
            ? AppColors.secondaryTeal
            : AppColors.textHeading;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveWidth(context, 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              vertical: isSelected ? 12 : 10,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: dayLabelColor,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
                Text(
                  day.dayNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: dayNumberColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          SizedBox(
            height: ResponsiveHelper.getResponsiveSize(context, 6),
            child: isIndicator
                ? Container(
                    width: ResponsiveHelper.getResponsiveSize(context, 6),
                    height: ResponsiveHelper.getResponsiveSize(context, 6),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryTeal,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day summary header
// ─────────────────────────────────────────────────────────────────────────────

class _DaySummaryHeader extends StatelessWidget {
  final String dateLabel;
  final String summaryLabel;
  final String openLabel;

  const _DaySummaryHeader({
    required this.dateLabel,
    required this.summaryLabel,
    required this.openLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
                  color: AppColors.textHeading,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                summaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
        Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 11,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.criticalBackground,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 999),
            ),
          ),
          child: Text(
            openLabel,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.criticalRed,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shift timeline row
// ─────────────────────────────────────────────────────────────────────────────

class _ShiftTimelineRow extends StatelessWidget {
  final CalendarShift shift;
  final bool isLast;

  const _ShiftTimelineRow({
    required this.shift,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(shift.status);
    final railWidth = ResponsiveHelper.getResponsiveWidth(context, 52);
    final haloSize = ResponsiveHelper.getResponsiveSize(context, 26);
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 10);
    final markerTop = ResponsiveHelper.getResponsiveHeight(context, 38);

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : ResponsiveHelper.getResponsiveHeight(context, 4),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: railWidth,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (!isLast)
                    Positioned(
                      top: markerTop + haloSize / 2,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 1.5,
                          color: AppColors.timelineDivider,
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shift.startTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                          color: AppColors.textHeading,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                      Text(
                        shift.startPeriod,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                      SizedBox(
                        width: haloSize,
                        height: haloSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: haloSize,
                              height: haloSize,
                              decoration: BoxDecoration(
                                color: style.background,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                color: style.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _ShiftCard(shift: shift, style: style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageStyle {
  final Color accent;
  final Color background;

  const _CoverageStyle({required this.accent, required this.background});
}

_CoverageStyle _statusStyle(CoverageStatus status) {
  switch (status) {
    case CoverageStatus.almostFull:
      return const _CoverageStyle(
        accent: AppColors.urgentAmber,
        background: AppColors.urgentBackground,
      );
    case CoverageStatus.needsAttention:
      return const _CoverageStyle(
        accent: AppColors.criticalRed,
        background: AppColors.criticalBackground,
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shift card
// ─────────────────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  final CalendarShift shift;
  final _CoverageStyle style;

  const _ShiftCard({required this.shift, required this.style});

  static const _avatarPalettes = [
    (Color(0xFFDBEAFE), Color(0xFF1D4ED8)), // blue
    (Color(0xFFDCFCE7), Color(0xFF15803D)), // green
    (Color(0xFFEDE9FE), Color(0xFF6D28D9)), // purple
    (Color(0xFFCCFBF1), Color(0xFF0F766E)), // teal
    (Color(0xFFFEF3C7), Color(0xFFB45309)), // amber
  ];

  @override
  Widget build(BuildContext context) {
    final fill = (shift.filled / shift.total).clamp(0.0, 1.0);
    final barHeight = ResponsiveHelper.getResponsiveHeight(context, 6);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 20),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${shift.filled} / ${shift.total}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: style.accent,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            shift.timeRange,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 4),
            ),
            child: SizedBox(
              height: barHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFEDF2F7)),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(color: style.accent),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Row(
            children: [
              _AvatarStack(avatars: shift.avatars, palettes: _avatarPalettes),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Expanded(
                child: Text(
                  shift.namesSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (shift.openPositionsLabel != null) ...[
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
                Flexible(
                  child: _OpenPositionsBadge(label: shift.openPositionsLabel!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<StaffAvatar> avatars;
  final List<(Color, Color)> palettes;

  const _AvatarStack({required this.avatars, required this.palettes});

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 32);
    final overlap = ResponsiveHelper.getResponsiveWidth(context, 10);
    final totalWidth =
        size + (avatars.length > 1 ? (avatars.length - 1) * (size - overlap) : 0);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: palettes[i % palettes.length].$1,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceWhite, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatars[i].initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                    color: palettes[i % palettes.length].$2,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenPositionsBadge extends StatelessWidget {
  final String label;

  const _OpenPositionsBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.urgentBackground,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSvgIcon(
            AppAssets.alertTriangle,
            size: 11,
            color: AppColors.urgentAmber,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10.5),
                color: AppColors.urgentAmber,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
