import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/attendance_enums.dart';
import '../../domain/entities/attendance_overview.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_stat_row.dart';
import '../widgets/attendance_tab_bar.dart';
import '../widgets/late_arrivals_section.dart';
import '../widgets/missed_clock_ins_section.dart';
import '../widgets/overtime_section.dart';
import '../widgets/staff_status_section.dart';

/// The "Attendance" screen - "Attendance" tab of the HR portal.
///
/// Reproduction of the reference "Today / Late / Missed / OT - Attendance"
/// screenshots. All 4 states share the exact same header and segmented tab
/// bar, so they are implemented as a single page with an internal
/// GetX-driven tab selection rather than 4 separate pages/routes.
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
          return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
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

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const AttendanceHeader(),
                    AttendanceTabBar(
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
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  children: _buildTabContent(selectedTab, overview),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildTabContent(AttendanceTab tab, AttendanceOverview overview) {
    switch (tab) {
      case AttendanceTab.today:
        return [
          AttendanceStatRow(stats: overview.todayStats),
          const SizedBox(height: 16),
          StaffStatusSection(
            onDutyLabel: overview.staffOnDutyLabel,
            entries: overview.staffStatus,
          ),
        ];
      case AttendanceTab.late:
        return [
          AttendanceStatRow(stats: overview.lateStats),
          const SizedBox(height: 16),
          LateArrivalsSection(entries: overview.lateArrivals),
        ];
      case AttendanceTab.missed:
        return [
          AttendanceStatRow(stats: overview.missedStats),
          const SizedBox(height: 16),
          MissedClockInsSection(entries: overview.missedClockIns),
        ];
      case AttendanceTab.ot:
        return [
          AttendanceStatRow(stats: overview.otStats),
          const SizedBox(height: 16),
          OvertimeSection(entries: overview.overtimeEntries),
        ];
    }
  }
}

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
            const Icon(Icons.error_outline_rounded, color: AppColors.criticalRed, size: 40),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
