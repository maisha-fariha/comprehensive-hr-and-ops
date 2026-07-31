import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/section_header_row.dart';
import '../controllers/staff_attendance_controller.dart';
import '../widgets/break_row.dart';
import '../widgets/clock_out_button.dart';
import '../widgets/geofence_row.dart';
import '../widgets/on_shift_banner.dart';
import '../widgets/selfie_verification_row.dart';
import '../widgets/shift_details_card.dart';
import '../widgets/staff_attendance_header.dart';
import '../widgets/time_worked_card.dart';

/// "Attendance" — the Staff (care-worker) portal's clock-in/out screen.
///
/// Reproduction of the reference "Attendance" screenshot. Single,
/// non-tabbed screen (unlike the HR Attendance feature's segmented
/// Today/Late/Missed/OT tabs).
class StaffAttendancePage extends StatelessWidget {
  const StaffAttendancePage({super.key});

  StaffAttendanceController _resolveController() {
    try {
      return Get.find<StaffAttendanceController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffAttendanceController>(), permanent: true);
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
                child: StaffAttendanceHeader(onBackTap: () => Navigator.maybePop(context)),
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
                  children: [
                    OnShiftBanner(isOnShift: overview.isOnShift, startedLabel: overview.shiftStartedLabel),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    const SectionHeaderRow(title: 'Shift Details'),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    ShiftDetailsCard(
                      locationName: overview.shiftLocationName,
                      timeRange: overview.shiftTimeRange,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    TimeWorkedCard(elapsedTimeLabel: overview.elapsedTimeLabel),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    GeofenceRow(
                      isWithinGeofence: overview.isWithinGeofence,
                      address: overview.geofenceAddress,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    SelfieVerificationRow(
                      isVerified: overview.isSelfieVerified,
                      verifiedLabel: overview.selfieVerifiedLabel,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    BreakRow(isOnBreak: overview.isOnBreak, statusLabel: overview.breakStatusLabel),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 24)),
                    const ClockOutButton(),
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
