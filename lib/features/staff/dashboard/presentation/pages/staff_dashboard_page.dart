import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../controllers/staff_dashboard_controller.dart';
import '../widgets/staff_alerts_banner.dart';
import '../widgets/staff_dashboard_header.dart';
import '../widgets/staff_overview_section.dart';
import '../widgets/staff_quick_actions_section.dart';
import '../widgets/today_shift_card.dart';

/// The Staff Dashboard — "Home" screen of the Staff (care-worker) portal.
///
/// Reproduction of the reference "Home/Dashboard" screenshot. Distinct from
/// `ManagerDashboardPage` (a different portal/role), but reuses the same
/// gradient-header + floating-card visual language for consistency.
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
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
        }

        if (overview == null) {
          return _StaffDashboardError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading your dashboard.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final topInset = ResponsiveHelper.getResponsiveHeight(
              context,
              AppDimens.searchBarOverlap,
            ) +
            ResponsiveHelper.getResponsiveHeight(context, 18);

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                StaffDashboardHeader(overview: overview),
                Positioned(
                  left: ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                  right: ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                  bottom: -ResponsiveHelper.getResponsiveHeight(context, AppDimens.searchBarOverlap),
                  child: TodayShiftCard(shift: overview.todayShift),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    topInset,
                    ResponsiveHelper.getResponsiveWidth(context, AppDimens.screenPaddingHorizontal),
                    ResponsiveHelper.getResponsiveHeight(context, 42),
                  ),
                  children: [
                    StaffOverviewSection(stats: overview.overviewStats),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    StaffAlertsBanner(count: overview.alertCount, label: overview.alertLabel),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    StaffQuickActionsSection(actions: overview.quickActions),
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
