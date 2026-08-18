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
                ResponsiveHelper.getResponsiveHeight(context, 8),
                horizontalPad,
                ResponsiveHelper.getResponsiveHeight(context, 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MonthHeader(monthLabel: data.monthLabel),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
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
    final buttonSize = ResponsiveHelper.getResponsiveSize(context, 34);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MonthNavButton(size: buttonSize, rotated: true),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            _MonthNavButton(size: buttonSize, rotated: false),
          ],
        ),
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
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotated ? math.pi : 0,
        child: const AppSvgIcon(
          AppAssets.chevronRight,
          size: 15,
          color: AppColors.textHeading,
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

    // Reference: day abbreviation stays gray for indicator days;
    // only the date number turns teal.
    final dayLabelColor =
        isSelected ? Colors.white : AppColors.textFaint;

    final dayNumberColor = isSelected
        ? Colors.white
        : isIndicator
            ? AppColors.secondaryTeal
            : AppColors.textHeading;

    final verticalPad = ResponsiveHelper.getResponsiveHeight(context, 10);
    final horizontalPad = ResponsiveHelper.getResponsiveWidth(context, 8);
    final indicatorSlot = ResponsiveHelper.getResponsiveSize(context, 5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            vertical: verticalPad,
            horizontal: horizontalPad,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 14),
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
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
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
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
        SizedBox(
          height: indicatorSlot,
          width: indicatorSlot,
          child: isIndicator
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ],
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
    final haloSize = ResponsiveHelper.getResponsiveSize(context, 15);
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

  @override
  Widget build(BuildContext context) {
    final fill = (shift.filled / shift.total).clamp(0.0, 1.0);
    final barHeight = ResponsiveHelper.getResponsiveHeight(context, 8);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 24),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.05),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 4)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  shift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: AppColors.textHeading,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 12,
                  vertical: 6,
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
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
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
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: barHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFFEDF2F7)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    child: ColoredBox(color: style.accent),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
          Row(
            children: [
              _AvatarStack(avatars: shift.avatars),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Flexible(
                child: Text(
                  shift.namesSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (shift.openPositionsLabel != null) ...[
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                _OpenPositionsBadge(label: shift.openPositionsLabel!),
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

  const _AvatarStack({required this.avatars});

  static const _fallbackPalettes = [
    (Color(0xFFE6F0FF), Color(0xFF1E3A5F)),
    (Color(0xFFE6F6EC), Color(0xFF15803D)),
    (Color(0xFFF0E6FF), Color(0xFF6D28D9)),
    (Color(0xFFE6F4F1), Color(0xFF0D9488)),
    (Color(0xFFFEF3C7), Color(0xFFD97706)),
  ];

  static const _paletteByInitials = <String, (Color, Color)>{
    'SJ': (Color(0xFFE6F0FF), Color(0xFF1E3A5F)),
    'MT': (Color(0xFFE6F6EC), Color(0xFF15803D)),
    'PK': (Color(0xFFF0E6FF), Color(0xFF6D28D9)),
    'JL': (Color(0xFFE6F4F1), Color(0xFF0D9488)),
    'NP': (Color(0xFFFEF3C7), Color(0xFFD97706)),
    'TM': (Color(0xFFE0E7FF), Color(0xFF4338CA)),
    'DS': (Color(0xFFFCE7F3), Color(0xFFBE185D)),
  };

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveHelper.getResponsiveSize(context, 30);
    final overlap = ResponsiveHelper.getResponsiveWidth(context, 9);
    final totalWidth =
        size + (avatars.length > 1 ? (avatars.length - 1) * (size - overlap) : 0);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AvatarBubble(
                initials: avatars[i].initials,
                size: size,
                palette: _paletteByInitials[avatars[i].initials] ??
                    _fallbackPalettes[i % _fallbackPalettes.length],
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String initials;
  final double size;
  final (Color, Color) palette;

  const _AvatarBubble({
    required this.initials,
    required this.size,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.$1,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
          color: palette.$2,
          height: 1,
        ),
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.urgentBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSvgIcon(
            AppAssets.alertTriangle,
            size: 12,
            color: AppColors.urgentAmber,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.urgentAmber,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
