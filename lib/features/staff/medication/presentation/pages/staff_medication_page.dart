import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../controllers/staff_medication_controller.dart';
import '../widgets/administered_tab_view.dart';
import '../widgets/due_tab_view.dart';
import '../widgets/missed_tab_view.dart';
import '../widgets/refused_tab_view.dart';
import '../widgets/staff_medication_header.dart';
import '../widgets/staff_medication_tab_bar.dart';

/// The Staff "Medication MAR" screen — reproduces the "Due", "Administered",
/// "Missed" and "Refused" Medication screens from the reference screenshots
/// as ONE page with a shared header and an internal segmented tab control,
/// since all 4 screens share identical chrome and only the list content
/// below the tab bar changes.
///
/// Hosts [StaffBottomNavBar] with "MAR / Tasks" selected so the pushed route
/// still matches reference frames that show the staff bottom nav.
class StaffMedicationPage extends StatelessWidget {
  /// Index of the "MAR / Tasks" slot in [StaffBottomNavBar.items].
  static const int _marTasksTabIndex = 3;

  const StaffMedicationPage({super.key});

  StaffMedicationController _resolveController() {
    try {
      return Get.find<StaffMedicationController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffMedicationController>(), permanent: true);
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
        currentIndex: _marTasksTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;

        if (overview == null && controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
        }

        if (overview == null) {
          return _StaffMedicationError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading medications.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StaffMedicationHeader(title: overview.screenTitle),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 12,
                      bottom: 8,
                    ),
                    child: StaffMedicationTabBar(
                      selectedTab: controller.selectedTab.value,
                      administeredCount: overview.administeredDoses.length,
                      missedCount: overview.missedDoses.length,
                      onTabSelected: controller.selectTab,
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
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 4),
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 32),
                  ),
                  children: [
                    switch (controller.selectedTab.value) {
                      StaffMedicationTab.due => DueTabView(
                          dueNowDoses: overview.dueNowDoses,
                          laterTodayDoses: overview.laterTodayDoses,
                          onAdminister: controller.markAdministered,
                          onNotGiven: controller.markNotGiven,
                        ),
                      StaffMedicationTab.administered =>
                        AdministeredTabView(doses: overview.administeredDoses),
                      StaffMedicationTab.missed => MissedTabView(doses: overview.missedDoses),
                      StaffMedicationTab.refused => RefusedTabView(doses: overview.refusedDoses),
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

class _StaffMedicationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffMedicationError({required this.message, required this.onRetry});

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
