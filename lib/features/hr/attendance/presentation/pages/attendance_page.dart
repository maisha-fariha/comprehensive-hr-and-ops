import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../attendance_assets.dart';
import '../../attendance_constants.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../../domain/entities/attendance_stat.dart';
import '../../domain/entities/late_arrival_entry.dart';
import '../../domain/entities/missed_clock_in_entry.dart';
import '../../domain/entities/overtime_entry.dart';
import '../../domain/entities/staff_status_entry.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_avatar.dart';

/// The "Attendance" screen — "Attendance" tab of the HR portal.
///
/// Today, Late, Missed, and OT tab UIs are matched to their Figma references.
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  AttendanceController _resolveController() {
    try {
      return Get.find<AttendanceController>();
    } catch (_) {
      return Get.put(GetIt.instance<AttendanceController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _AttendanceError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading attendance.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final selectedTab = controller.selectedTab.value;
        final horizontalPad = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _AttendanceHeader(),
                    _AttendanceTabBar(
                      selected: selectedTab,
                      lateCount: overview.lateCount,
                      missedCount: overview.missedCount,
                      otCount: overview.otCount,
                      onSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    horizontalPad,
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  children: _buildTabContent(context, selectedTab, overview),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildTabContent(
    BuildContext context,
    AttendanceTab tab,
    AttendanceOverview overview,
  ) {
    switch (tab) {
      case AttendanceTab.today:
        return [
          _TodayStatRow(stats: overview.todayStats),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          _StaffStatusSection(
            onDutyLabel: overview.staffOnDutyLabel,
            entries: overview.staffStatus,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 35)),
          const _GeofenceCard(),
        ];
      case AttendanceTab.late:
        return [
          _LateStatRow(stats: overview.lateStats),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          _LateArrivalsSection(entries: overview.lateArrivals),
        ];
      case AttendanceTab.missed:
        return [
          _MissedStatRow(stats: overview.missedStats),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          _MissedClockInsSection(entries: overview.missedClockIns),
        ];
      case AttendanceTab.ot:
        return [
          _OtStatRow(stats: overview.otStats),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
          _OvertimeTrackingSection(entries: overview.overtimeEntries),
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader();

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveHelper.getResponsiveSize(
      context,
      AttendanceDimens.headerIconButtonSize,
    );

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            AttendanceMaterialIconFallback.menu,
            size: ResponsiveHelper.getResponsiveSize(context, 24),
            color: AppColors.textHeading,
          ),
          Expanded(
            child: Text(
              'Attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                color: AppColors.textHeading,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            alignment: Alignment.center,
            child: const AppSvgIcon(
              AppAssets.navCalendar,
              size: 18,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabSpec {
  final AttendanceTab tab;
  final String label;
  final int? badgeCount;
  final Color? badgeBackground;
  final Color? badgeForeground;

  const _TabSpec({
    required this.tab,
    required this.label,
    this.badgeCount,
    this.badgeBackground,
    this.badgeForeground,
  });
}

class _AttendanceTabBar extends StatelessWidget {
  final AttendanceTab selected;
  final int lateCount;
  final int missedCount;
  final int otCount;
  final ValueChanged<AttendanceTab> onSelected;

  const _AttendanceTabBar({
    required this.selected,
    required this.lateCount,
    required this.missedCount,
    required this.otCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final specs = [
      const _TabSpec(tab: AttendanceTab.today, label: 'Today'),
      _TabSpec(
        tab: AttendanceTab.late,
        label: 'Late',
        badgeCount: lateCount,
        badgeBackground: AppColors.urgentBackground,
        badgeForeground: AppColors.urgentAmber,
      ),
      _TabSpec(
        tab: AttendanceTab.missed,
        label: 'Missed',
        badgeCount: missedCount,
        badgeBackground: AppColors.criticalBackground,
        badgeForeground: AppColors.criticalRed,
      ),
      _TabSpec(
        tab: AttendanceTab.ot,
        label: 'OT',
        badgeCount: otCount,
        badgeBackground: AppColors.infoBackground,
        badgeForeground: AppColors.infoBlue,
      ),
    ];

    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        bottom: 14,
      ),
      child: Container(
        height: ResponsiveHelper.getResponsiveHeight(
          context,
          AttendanceDimens.tabBarHeight,
        ),
        padding: ResponsiveHelper.getResponsivePadding(context, all: 3),
        decoration: BoxDecoration(
          color: AppColors.filterButtonBackground,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveRadius(
              context,
              AttendanceDimens.tabBarRadius,
            ),
          ),
        ),
        child: Row(
          children: [
            for (final spec in specs)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(spec.tab),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveWidth(context, 2),
                    ),
                    decoration: BoxDecoration(
                      color: spec.tab == selected
                          ? AppColors.surfaceWhite
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(
                          context,
                          AttendanceDimens.tabBarRadius - 2,
                        ),
                      ),
                      boxShadow: spec.tab == selected
                          ? [
                              BoxShadow(
                                color: AppColors.shadowNavy.withValues(alpha: 0.08),
                                offset: Offset(
                                  0,
                                  ResponsiveHelper.getResponsiveHeight(context, 1),
                                ),
                                blurRadius: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  3,
                                ),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            spec.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: spec.tab == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12.5,
                              ),
                              color: spec.tab == selected
                                  ? AppColors.secondaryTeal
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (spec.tab != selected &&
                            (spec.badgeCount ?? 0) > 0) ...[
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(context, 4),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: ResponsiveHelper.getResponsiveSize(context, 16),
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: spec.badgeBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${spec.badgeCount}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  10,
                                ),
                                color: spec.badgeForeground,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Today — summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _TodayStatRow extends StatelessWidget {
  final List<AttendanceStat> stats;

  const _TodayStatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _TodayStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _TodayStatCard extends StatelessWidget {
  final AttendanceStat stat;

  const _TodayStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final (iconColor, iconBg, valueColor) = _toneColors(stat.tone);
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 36);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        vertical: 14,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 11),
              ),
            ),
            alignment: Alignment.center,
            child: stat.iconAsset != null
                ? AppSvgIcon(stat.iconAsset!, size: 17, color: iconColor)
                : Icon(
                    stat.iconData,
                    size: ResponsiveHelper.getResponsiveSize(context, 17),
                    color: iconColor,
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              color: valueColor,
              letterSpacing: -0.4,
              height: 1,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color) _toneColors(AttendanceStatTone tone) {
    switch (tone) {
      case AttendanceStatTone.positive:
        return (
          AppColors.activeGreen,
          AppColors.activeIconBackground,
          AppColors.activeGreen,
        );
      case AttendanceStatTone.warning:
        return (
          AppColors.urgentAmber,
          AppColors.urgentIconBackground,
          AppColors.urgentAmber,
        );
      case AttendanceStatTone.critical:
        return (
          AppColors.criticalRed,
          AppColors.criticalIconBackground,
          AppColors.criticalRed,
        );
      case AttendanceStatTone.info:
        return (
          AppColors.infoBlue,
          AppColors.infoIconBackground,
          AppColors.textHeading,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today — staff status
// ─────────────────────────────────────────────────────────────────────────────

class _StaffStatusSection extends StatelessWidget {
  final String onDutyLabel;
  final List<StaffStatusEntry> entries;

  const _StaffStatusSection({
    required this.onDutyLabel,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Staff Status',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              onDutyLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _StaffStatusTile(entry: entries[i]),
        ],
      ],
    );
  }
}

class _StaffStatusTile extends StatelessWidget {
  final StaffStatusEntry entry;

  const _StaffStatusTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMissed = entry.status == StaffAttendanceStatus.missed;
    final statusLabel = switch (entry.status) {
      StaffAttendanceStatus.onTime => 'On Time',
      StaffAttendanceStatus.late => 'Late',
      StaffAttendanceStatus.missed => 'Missed',
    };
    final statusColor = switch (entry.status) {
      StaffAttendanceStatus.onTime => AppColors.activeGreen,
      StaffAttendanceStatus.late => AppColors.urgentAmber,
      StaffAttendanceStatus.missed => AppColors.criticalRed,
    };
    final palette = attendanceAvatarPalette[
        entry.avatarPaletteIndex % attendanceAvatarPalette.length];
    final avatarSize = ResponsiveHelper.getResponsiveSize(
      context,
      AttendanceDimens.avatarSize,
    );
    final dotSize = ResponsiveHelper.getResponsiveSize(context, 11);

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.initials,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        13.5,
                      ),
                      color: palette.foreground,
                      height: 1,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: isMissed
                          ? AppColors.textFaint
                          : AppColors.activeGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceWhite,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: AppColors.textHeading,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Row(
                  children: [
                    AppSvgIcon(
                      isMissed
                          ? 'assets/icons/attendance/no_location.svg'
                          : 'assets/icons/attendance/location.svg',
                      size: 13,
                      color: isMissed
                          ? AppColors.criticalRed
                          : AppColors.textFaint,
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveWidth(context, 3),
                    ),
                    Flexible(
                      child: Text(
                        entry.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                          ),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: statusColor,
                  height: 1,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 5)),
              Text(
                entry.timeLabel ?? '—',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today — geofence status (standalone card below Staff Status)
// ─────────────────────────────────────────────────────────────────────────────

/// Geofence verification card shown under Today's Staff Status list.
///
/// Icon note: no shield SVG exists in `assets/icons/attendance`, so
/// [Icons.verified_user_outlined] and [Icons.check_rounded] stand in for
/// the shield / active-check glyphs until matching assets are added.
class _GeofenceCard extends StatelessWidget {
  static const Color _mintSoft = Color(0xFFEAF6F0);
  static const Color _mintAccent = Color(0xFF2E8C58);

  const _GeofenceCard();

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 18);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: _mintSoft,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icons/attendance/shield.svg',
              width: ResponsiveHelper.getResponsiveSize(context, 22),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Geofence: Sunrise Home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: AppColors.textHeading,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 3)),
                Text(
                  'Verification radius · 500 ft',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: AppColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          Container(
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _mintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 13),
                  color: _mintAccent,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: _mintAccent,
                    height: 1,
                  ),
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
// Late — summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _LateStatRow extends StatelessWidget {
  final List<AttendanceStat> stats;

  const _LateStatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _TodayStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Late — arrivals list
// ─────────────────────────────────────────────────────────────────────────────

class _LateArrivalsSection extends StatelessWidget {
  final List<LateArrivalEntry> entries;

  const _LateArrivalsSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Late Arrivals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              'Today',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _LateArrivalCard(entry: entries[i]),
        ],
      ],
    );
  }
}

class _LateArrivalCard extends StatelessWidget {
  final LateArrivalEntry entry;

  const _LateArrivalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = attendanceAvatarPalette[
        entry.avatarPaletteIndex % attendanceAvatarPalette.length];
    final avatarSize = ResponsiveHelper.getResponsiveSize(
      context,
      AttendanceDimens.avatarSize,
    );
    final initials = initialsFromName(entry.name);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.03),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 2)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: palette.foreground,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                    Text(
                      entry.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.urgentBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.lateLabel,
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
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          const Divider(height: 1, thickness: 1, color: AppColors.dividerLight),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SCHEDULED',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10,
                          ),
                          color: AppColors.textFaint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      ),
                      Text(
                        entry.scheduledRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 8),
                      ),
                      Row(
                        children: [
                          const AppSvgIcon(
                            'assets/icons/attendance/location.svg',
                            size: 13,
                            color: AppColors.textFaint,
                          ),
                          SizedBox(
                            width: ResponsiveHelper.getResponsiveWidth(context, 3),
                          ),
                          Flexible(
                            child: Text(
                              entry.distanceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  11.5,
                                ),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveWidth(context, 12),
                  ),
                  child: const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.dividerLight,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CLOCKED IN',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10,
                          ),
                          color: AppColors.textFaint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      ),
                      Text(
                        entry.clockedInTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: AppColors.urgentAmber,
                        ),
                      ),
                    ],
                  ),
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
// Missed — summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _MissedStatRow extends StatelessWidget {
  final List<AttendanceStat> stats;

  const _MissedStatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _TodayStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Missed — clock-ins list
// ─────────────────────────────────────────────────────────────────────────────

class _MissedClockInsSection extends StatelessWidget {
  final List<MissedClockInEntry> entries;

  const _MissedClockInsSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Missed Clock-Ins',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              'Needs review',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _MissedClockInCard(entry: entries[i]),
        ],
      ],
    );
  }
}

class _MissedClockInCard extends StatelessWidget {
  final MissedClockInEntry entry;

  const _MissedClockInCard({required this.entry});

  static const _avatarByInitials = <String, (Color, Color)>{
    'JL': (Color(0xFFFBEAEA), Color(0xFFC45C5C)),
    'OF': (Color(0xFFF0ECFB), Color(0xFF6A4BC7)),
  };

  static const _reasonText = Color(0xFF8B5A4A);
  static const _reasonBackground = Color(0xFFF7F0EE);

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(entry.name);
    final palette = _avatarByInitials[initials] ??
        (
          attendanceAvatarPalette[
                  entry.avatarPaletteIndex % attendanceAvatarPalette.length]
              .background,
          attendanceAvatarPalette[
                  entry.avatarPaletteIndex % attendanceAvatarPalette.length]
              .foreground,
        );
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 44);
    final buttonHeight = ResponsiveHelper.getResponsiveHeight(context, 42);
    final badgeIconSize = ResponsiveHelper.getResponsiveSize(context, 14);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 18),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
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
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: palette.$1,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    color: palette.$2,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          15,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                    Text(
                      entry.roleShiftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Flexible(
                child: Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: badgeIconSize,
                        height: badgeIconSize,
                        decoration: BoxDecoration(
                          color: AppColors.criticalRed.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.criticalRed,
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.close_rounded,
                          size: ResponsiveHelper.getResponsiveSize(context, 9),
                          color: AppColors.criticalRed,
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveHelper.getResponsiveWidth(context, 5),
                      ),
                      Flexible(
                        child: Text(
                          'No Clock In',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              11,
                            ),
                            color: AppColors.criticalRed,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Container(
            width: double.infinity,
            padding: ResponsiveHelper.getResponsivePadding(
              context,
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: _reasonBackground,
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: _reasonText,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          13,
                        ),
                        color: _reasonText,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Reason: ',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: entry.reasonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Review',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// OT — summary stats
// ─────────────────────────────────────────────────────────────────────────────

class _OtStatRow extends StatelessWidget {
  final List<AttendanceStat> stats;

  const _OtStatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i != 0)
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
            Expanded(child: _TodayStatCard(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OT — overtime tracking
// ─────────────────────────────────────────────────────────────────────────────

class _OvertimeTrackingSection extends StatelessWidget {
  final List<OvertimeEntry> entries;

  const _OvertimeTrackingSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Overtime Tracking',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Text(
              'This week',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textFaint,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        for (var i = 0; i < entries.length; i++) ...[
          if (i != 0)
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
          _OvertimeCard(entry: entries[i]),
        ],
      ],
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  final OvertimeEntry entry;

  const _OvertimeCard({required this.entry});

  static const _avatarByInitials = <String, (Color, Color)>{
    'TM': (Color(0xFFE6F0FF), Color(0xFF1E3A5F)),
    'NP': (Color(0xFFE6F6EC), Color(0xFF15803D)),
    'CB': (Color(0xFFF0E6FF), Color(0xFF6D28D9)),
  };

  @override
  Widget build(BuildContext context) {
    final isExceeded = entry.status == OvertimeStatus.exceeded;
    final accent = isExceeded ? AppColors.criticalRed : AppColors.urgentAmber;
    final badgeBg =
        isExceeded ? AppColors.criticalBackground : AppColors.urgentBackground;
    final badgeLabel =
        isExceeded ? 'Overtime Exceeded' : 'Approaching Limit';
    final initials = initialsFromName(entry.name);
    final palette = _avatarByInitials[initials] ??
        (
          attendanceAvatarPalette[
                  entry.avatarPaletteIndex % attendanceAvatarPalette.length]
              .background,
          attendanceAvatarPalette[
                  entry.avatarPaletteIndex % attendanceAvatarPalette.length]
              .foreground,
        );
    final avatarSize = ResponsiveHelper.getResponsiveSize(context, 42);
    final barHeight = ResponsiveHelper.getResponsiveHeight(context, 8);
    final fill = entry.progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 18),
        ),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowNavy.withValues(alpha: 0.04),
            offset: Offset(0, ResponsiveHelper.getResponsiveHeight(context, 3)),
            blurRadius: ResponsiveHelper.getResponsiveHeight(context, 10),
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
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: palette.$1,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                    color: palette.$2,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          15,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 3),
                    ),
                    Text(
                      entry.roleShiftLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Flexible(
                child: Container(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        10.5,
                      ),
                      color: accent,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OT TODAY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10,
                          ),
                          color: AppColors.textFaint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      ),
                      Text(
                        entry.otTodayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            15,
                          ),
                          color: AppColors.urgentAmber,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveWidth(context, 12),
                  ),
                  child: const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.dividerLight,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WEEKLY TOTAL',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            10,
                          ),
                          color: AppColors.textFaint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 4),
                      ),
                      Text(
                        entry.weeklyTotalLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            15,
                          ),
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    child: ColoredBox(color: accent),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            entry.limitCaption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AttendanceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: ResponsiveHelper.getResponsiveSize(context, 40),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
