import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_attendance_controller.dart';
import '../widgets/attendance_history_section.dart';
import '../widgets/break_row.dart';
import '../widgets/on_shift_banner.dart';
import '../widgets/selfie_verification_row.dart';
import '../widgets/shift_details_card.dart';
import '../widgets/staff_attendance_filters_bar.dart';
import '../widgets/staff_attendance_header.dart';
import '../widgets/staff_attendance_metrics_strip.dart';

/// Staff Attendance — web-parity metrics, filters, list, and clock in/out.
class StaffAttendancePage extends StatelessWidget {
  const StaffAttendancePage({super.key});

  static const int _moreTabIndex = 4;

  StaffAttendanceController _resolveController() {
    try {
      return Get.find<StaffAttendanceController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<StaffAttendanceController>(),
        permanent: true,
      );
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _moreTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _StaffAttendanceError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading attendance.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: SafeArea(
                bottom: false,
                child: StaffAttendanceHeader(
                  onBackTap: () => Navigator.maybePop(context),
                  isOnShift: overview.isOnShift,
                  onClockInTap: controller.clockIn,
                  onClockOutTap: controller.clockOut,
                  onManualEntryTap: controller.showManualEntryDialog,
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
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(
                      context,
                      AppDimens.screenPaddingHorizontal,
                    ),
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  children: [
                    StaffAttendanceMetricsStrip(metrics: overview.metrics),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    if (overview.isOnShift) ...[
                      OnShiftBanner(
                        isOnShift: overview.isOnShift,
                        startedLabel: overview.shiftStartedLabel,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      const SectionHeaderRow(title: 'Shift Details'),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 12),
                      ),
                      ShiftDetailsCard(
                        locationName: overview.shiftLocationName,
                        timeRange: overview.shiftTimeRange,
                        elapsedTimeLabel: controller.liveElapsedLabel.value,
                        isWithinGeofence: overview.isWithinGeofence,
                        geofenceStatusLabel: overview.geofenceStatusLabel,
                        geofenceAddress: overview.geofenceAddress,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      SelfieVerificationRow(
                        isVerified: overview.isSelfieVerified,
                        verifiedLabel: overview.selfieVerifiedLabel,
                        selfieUrl: overview.selfieUrl,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 14),
                      ),
                      BreakRow(
                        isOnBreak: overview.isOnBreak,
                        statusLabel: overview.breakStatusLabel,
                        onToggleBreak: controller.toggleBreak,
                      ),
                      SizedBox(
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 20),
                      ),
                    ],
                    StaffAttendanceFiltersBar(
                      selectedDate: controller.historyDateFilter.value,
                      residenceFilter: controller.historyResidenceFilter.value,
                      statusFilter: controller.historyStatusFilter.value,
                      residences: controller.residenceOptions.toList(),
                      onDateChanged: controller.setHistoryDateFilter,
                      onResidenceChanged:
                          controller.setHistoryResidenceFilter,
                      onStatusChanged: controller.setHistoryStatusFilter,
                    ),
                    SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 16),
                    ),
                    AttendanceHistorySection(
                      items: controller.filteredHistory,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StaffAttendanceError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffAttendanceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
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
