import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/medication_enums.dart';
import '../controllers/medication_controller.dart';
import '../widgets/due_tab_view.dart';
import '../widgets/medication_header.dart';
import '../widgets/medication_tab_bar.dart';
import '../widgets/missed_tab_view.dart';
import '../widgets/overview_tab_view.dart';
import '../widgets/refused_tab_view.dart';

/// The "Medication MAR" screen — reproduces the "Overview", "Due",
/// "Missed" and "Refused" Medication screens from the reference design as
/// ONE page with a shared header and an internal segmented tab control,
/// since all 4 screens share identical chrome and only the list content
/// below the tab bar changes.
class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key});

  MedicationController _resolveController() {
    try {
      return Get.find<MedicationController>();
    } catch (_) {
      return Get.put(GetIt.instance<MedicationController>(), permanent: true);
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
          return _MedicationError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading medications.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            MedicationHeader(title: overview.screenTitle, subtitle: overview.screenSubtitle),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, top: 12, bottom: 8),
              child: MedicationTabBar(
                selectedTab: controller.selectedTab.value,
                dueCount: overview.dueCount,
                missedCount: overview.missedCount,
                refusedCount: overview.refusedCount,
                onTabSelected: controller.selectTab,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 4),
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 32),
                  ),
                  children: [
                    switch (controller.selectedTab.value) {
                      MedicationTab.overview => OverviewTabView(
                          stats: overview.overviewStats,
                          dueTodayDoses: overview.dueTodayDoses,
                          moreDueTodayCount: overview.moreDueTodayCount,
                          missedRefusedAlerts: overview.missedRefusedAlerts,
                          missedRefusedAlertCount: overview.missedCount + overview.refusedCount,
                        ),
                      MedicationTab.due => DueTabView(
                          title: overview.scheduleTitle,
                          subtitle: overview.scheduleSubtitle,
                          selectedPeriod: controller.selectedSchedulePeriod.value,
                          onPeriodSelected: controller.selectSchedulePeriod,
                          priorityDoses: overview.priorityDoses,
                          laterTodayDoses: overview.laterTodayDoses,
                        ),
                      MedicationTab.missed => MissedTabView(
                          stats: overview.missedStats,
                          medications: overview.missedMedications,
                        ),
                      MedicationTab.refused => RefusedTabView(
                          stats: overview.refusedStats,
                          medications: overview.refusedMedications,
                        ),
                    },
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

class _MedicationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MedicationError({required this.message, required this.onRetry});

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
