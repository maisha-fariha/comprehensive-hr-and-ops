import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../attendance/domain/repositories/staff_attendance_repository.dart';
import '../../../attendance/presentation/widgets/staff_clock_action_sheet.dart';
import '../../../../common/inbox/presentation/pages/portal_notifications_page.dart';
import '../../../extras/presentation/widgets/staff_raise_emergency_dialog.dart';
import '../../../medication/presentation/pages/staff_medication_page.dart';
import '../../../presentation/open_staff_profile.dart';
import '../../../search/presentation/pages/staff_search_page.dart';
import '../../../staff_shell.dart';
import '../../../tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../controllers/staff_dashboard_controller.dart';
import '../widgets/staff_alerts_banner.dart';
import '../widgets/staff_dashboard_header.dart';
import '../widgets/staff_home_search_bar.dart';
import '../widgets/staff_overview_section.dart';
import '../widgets/staff_quick_actions_section.dart';
import '../widgets/today_shift_card.dart';

/// The Staff Dashboard — "Home" screen of the Staff (care-worker) portal.
class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  StaffDashboardController _resolveController() {
    final session = Get.find<UserSession>();
    if (Get.isRegistered<StaffDashboardController>()) {
      final existing = Get.find<StaffDashboardController>();
      if (existing.boundUserId == null ||
          existing.boundUserId == session.userId) {
        return existing;
      }
      Get.delete<StaffDashboardController>(force: true);
      try {
        GetIt.instance.resetLazySingleton<StaffDashboardController>();
      } catch (_) {}
    }
    return Get.put(
      GetIt.instance<StaffDashboardController>(),
      permanent: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(() {
        final overview = controller.state.value.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _StaffDashboardError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading your dashboard.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final horizontal = ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        );
        final overlap = ResponsiveHelper.getResponsiveHeight(
          context,
          kStaffShiftCardOverlap,
        );
        final afterShiftGap = overlap + ResponsiveHelper.getResponsiveHeight(context, 16);

        return RefreshIndicator(
          color: AppColors.secondaryTeal,
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StaffDashboardHeader(
                      overview: overview,
                      showPanicButton:
                          Get.find<UserSession>().canRaiseEmergency,
                      onNotificationsTap: () =>
                          Get.to(() => const PortalNotificationsPage()),
                      onPanicTap: () => StaffRaiseEmergencyDialog.show(),
                      onAvatarTap: () {
                        openStaffProfile();
                      },
                    ),
                    // Overlaps the header visually. IgnorePointer so it cannot
                    // steal taps from the avatar / bell (BUG_Report001).
                    Positioned(
                      left: horizontal,
                      right: horizontal,
                      bottom: -overlap,
                      child: IgnorePointer(
                        child: TodayShiftCard(shift: overview.todayShift),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: afterShiftGap),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    0,
                    horizontal,
                    ResponsiveHelper.getResponsiveHeight(context, 28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StaffHomeSearchBar(onTap: StaffSearchPage.open),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                      StaffOverviewSection(stats: overview.overviewStats),
                      if (overview.alertCount > 0) ...[
                        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                        StaffAlertsBanner(
                          count: overview.alertCount,
                          label: overview.alertLabel,
                        ),
                      ],
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),
                      StaffQuickActionsSection(
                        actions: overview.quickActions,
                        clockBusy: controller.clockBusy.value,
                        onActionTap: (action) {
                          switch (action.id) {
                            case 'clock-in-out':
                              _openClockSheet(context, controller);
                            case 'daily-logs':
                              // Opens Daily Logs tab (My Clients / notes).
                              Get.offAll(() => const StaffShell(initialIndex: 2));
                            case 'medication-mar':
                              // Opens MAR → GET /mar/round
                              Get.to(() => const StaffMedicationPage());
                            case 'my-tasks':
                              // Opens Tasks → GET /tasks?assignee=me
                              Get.to(() => const StaffTasksMessagesPage());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Same clock dialog as Attendance: a residence is required, photo and
  /// location are optional. A bare check-in without a residence is rejected.
  Future<void> _openClockSheet(
    BuildContext context,
    StaffDashboardController controller,
  ) async {
    final shift = controller.overview?.todayShift;
    if (shift == null || controller.clockBusy.value) return;
    if (!GetIt.instance.isRegistered<StaffAttendanceRepository>()) return;
    final attendance = GetIt.instance<StaffAttendanceRepository>();
    final residences = await attendance.getResidences();
    if (!context.mounted) return;
    if (residences.isFailure) {
      AppErrorDialog.showResultError(
        residences.error,
        fallbackTitle: 'Could not load residences',
      );
      return;
    }
    final saved = await StaffClockActionSheet.show(
      context,
      isCheckIn: !shift.onShift,
      residences: residences.value ?? const [],
      initialResidenceId: shift.residenceId,
      shiftId: shift.shiftId,
      showNotRosteredWarning:
          !shift.onShift && (shift.shiftId == null || shift.shiftId!.isEmpty),
    );
    if (saved == true) await controller.refresh();
  }
}

class _StaffDashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffDashboardError({required this.message, required this.onRetry});

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
