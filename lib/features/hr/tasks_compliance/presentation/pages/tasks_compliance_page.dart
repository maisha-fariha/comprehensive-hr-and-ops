import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../domain/entities/tasks_compliance_enums.dart';
import '../controllers/tasks_compliance_controller.dart';
import '../widgets/compliance_tab_view.dart';
import '../widgets/corrective_tab_view.dart';
import '../widgets/tasks_compliance_header.dart';
import '../widgets/tasks_compliance_tab_bar.dart';
import '../widgets/tasks_tab_view.dart';

/// The "Tasks & Compliance" screen — shared white header + pill tab bar,
/// with Tasks / Compliance / Corrective body content.
///
/// Hosts [HrBottomNavBar] with "More" selected so the pushed route still
/// matches the reference frames that show the manager bottom nav.
class TasksCompliancePage extends StatelessWidget {
  const TasksCompliancePage({super.key});

  /// Index of the "More" slot in [HrBottomNavBar.items].
  static const int _moreTabIndex = 4;

  TasksComplianceController _resolveController() {
    try {
      return Get.find<TasksComplianceController>();
    } catch (_) {
      return Get.put(GetIt.instance<TasksComplianceController>(), permanent: true);
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => HrShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: HrBottomNavBar(
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
          return _TasksComplianceError(
            message: controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading Tasks & Compliance.'
                : controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  TasksComplianceHeader(subtitle: overview.headerSubtitle),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 12,
                    ),
                    child: TasksComplianceTabBar(
                      selectedTab: controller.selectedTab.value,
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
                    ResponsiveHelper.getResponsiveHeight(context, 16),
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 24),
                  ),
                  children: [
                    switch (controller.selectedTab.value) {
                      TasksComplianceTab.tasks => TasksTabView(overview: overview),
                      TasksComplianceTab.compliance =>
                        ComplianceTabView(overview: overview),
                      TasksComplianceTab.corrective =>
                        CorrectiveTabView(overview: overview),
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

class _TasksComplianceError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TasksComplianceError({required this.message, required this.onRetry});

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
