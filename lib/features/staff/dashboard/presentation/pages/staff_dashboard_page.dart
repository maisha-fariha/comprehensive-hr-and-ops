import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../../medication/presentation/pages/staff_medication_page.dart';
import '../../../staff_shell.dart';
import '../../../tasks_messages/presentation/pages/staff_tasks_messages_page.dart';
import '../controllers/staff_dashboard_controller.dart';
import '../widgets/staff_alerts_banner.dart';
import '../widgets/staff_dashboard_header.dart';
import '../widgets/staff_overview_section.dart';
import '../widgets/staff_quick_actions_section.dart';
import '../widgets/today_shift_card.dart';

/// The Staff Dashboard — "Home" screen of the Staff (care-worker) portal.
class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  StaffDashboardController _resolveController() {
    try {
      return Get.find<StaffDashboardController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffDashboardController>(), permanent: true);
    }
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
                    StaffDashboardHeader(overview: overview),
                    Positioned(
                      left: horizontal,
                      right: horizontal,
                      bottom: -overlap,
                      child: TodayShiftCard(shift: overview.todayShift),
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
                        onActionTap: (action) {
                          switch (action.id) {
                            case 'clock-in-out':
                              Get.to(() => const StaffAttendancePage());
                            case 'daily-logs':
                              Get.offAll(() => const StaffShell(initialIndex: 2));
                            case 'medication-mar':
                              Get.to(() => const StaffMedicationPage());
                            case 'my-tasks':
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
