import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../common/inbox/domain/entities/portal_search_hit.dart';
import '../../../../common/inbox/presentation/pages/portal_notifications_page.dart';
import '../../../../common/inbox/presentation/pages/portal_search_page.dart';
import '../../../attendance/presentation/pages/staff_attendance_page.dart';
import '../../../incidents/presentation/pages/staff_incidents_list_page.dart';
import '../../../medication/presentation/pages/staff_medication_page.dart';
import '../../../profile_settings/presentation/pages/staff_profile_settings_page.dart';
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
                    StaffDashboardHeader(
                      overview: overview,
                      onNotificationsTap: () =>
                          Get.to(() => const PortalNotificationsPage()),
                      onAvatarTap: () =>
                          Get.to(() => const StaffProfileSettingsPage()),
                    ),
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
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                      _StaffSearchBar(onTap: _openStaffSearch),
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

void _openStaffSearch() {
  Get.to(
    () => PortalSearchPage(
      hint: 'Search clients, shifts, or tasks',
      emptyPrompt: 'Search your assigned work and records.',
      onHit: (hit) {
        Get.back();
        switch (hit.type) {
          case PortalSearchHitType.shift:
            Get.offAll(() => const StaffShell(initialIndex: 1));
          case PortalSearchHitType.client:
            Get.offAll(() => const StaffShell(initialIndex: 2));
          case PortalSearchHitType.task:
          case PortalSearchHitType.message:
            Get.to(() => const StaffTasksMessagesPage());
          case PortalSearchHitType.medication:
            Get.to(() => const StaffMedicationPage());
          case PortalSearchHitType.incident:
            Get.to(() => const StaffIncidentsListPage());
          case PortalSearchHitType.attendance:
            Get.to(() => const StaffAttendancePage());
          case PortalSearchHitType.staff:
          case PortalSearchHitType.document:
          case PortalSearchHitType.unknown:
            break;
        }
      },
    ),
  );
}

class _StaffSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _StaffSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveHeight(context, 48);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 4),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const AppSvgIcon(AppAssets.search, size: 18, color: AppColors.textFaint),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
            Text(
              'Search clients, shifts, or tasks',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
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
