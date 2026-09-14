import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../staff_shell.dart';
import '../controllers/staff_schedule_controller.dart';
import '../widgets/my_shifts_section.dart';
import '../widgets/open_shift_requests_section.dart';
import '../widgets/staff_schedule_header.dart';
import '../widgets/swap_requests_section.dart';
import '../widgets/upcoming_appointments_section.dart';
import '../widgets/week_navigator.dart';

/// "My Schedule" — the Staff (care-worker) portal's Scheduling screen.
class StaffSchedulePage extends StatelessWidget {
  const StaffSchedulePage({super.key});

  StaffScheduleController _resolveController() {
    try {
      return Get.find<StaffScheduleController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffScheduleController>(), permanent: true);
    }
  }

  void _onBack() {
    Get.offAll(() => const StaffShell(initialIndex: 0));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (overview == null) {
            return _StaffScheduleError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading your schedule.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final selectedShifts = controller.shiftsForSelectedDay;
          final dayLabel = controller.selectedDayShiftsLabel;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  children: [
                    StaffScheduleHeader(onBackTap: _onBack),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: AppDimens.screenPaddingHorizontal,
                        bottom: 16,
                      ),
                      child: WeekNavigator(
                        weekRangeLabel: overview.weekRangeLabel,
                        days: overview.weekDays,
                        onPreviousWeek: controller.goToPreviousWeek,
                        onNextWeek: controller.goToNextWeek,
                        onDaySelected: controller.selectDay,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 18),
                      ResponsiveHelper.getResponsiveWidth(
                        context,
                        AppDimens.screenPaddingHorizontal,
                      ),
                      ResponsiveHelper.getResponsiveHeight(context, 42),
                    ),
                    children: [
                      MyShiftsSection(
                        shiftsThisWeekLabel: dayLabel,
                        shifts: selectedShifts,
                        onShiftTap: controller.openShiftDetail,
                        onRequestSwap: controller.requestCoverSwap,
                      ),
                      if (selectedShifts.isEmpty) ...[
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            12,
                          ),
                        ),
                        Text(
                          'No shifts on this day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              13,
                            ),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 18),
                      ),
                      OpenShiftRequestsSection(
                        shifts: overview.openShiftRequests,
                        onRequestTap: (shift) =>
                            controller.requestOpenShift(shift.id),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 18),
                      ),
                      SwapRequestsSection(
                        swaps: overview.swapRequests,
                        onAccept: (swap) => controller.respondToSwap(
                          swapId: swap.id,
                          accepted: true,
                        ),
                        onDecline: (swap) => controller.respondToSwap(
                          swapId: swap.id,
                          accepted: false,
                        ),
                        onCancel: (swap) => controller.cancelSwap(swap.id),
                      ),
                      if (Get.find<UserSession>()
                          .canSeeStaffScheduleAppointments) ...[
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveHeight(
                            context,
                            18,
                          ),
                        ),
                        UpcomingAppointmentsSection(
                          appointments: overview.appointments,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StaffScheduleError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffScheduleError({required this.message, required this.onRetry});

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
