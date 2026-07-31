import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/scheduling_enums.dart';
import '../controllers/scheduling_controller.dart';
import '../widgets/board_tab_view.dart';
import '../widgets/calendar_tab_view.dart';
import '../widgets/requests_tab_view.dart';
import '../widgets/scheduling_segmented_tabs.dart';
import '../widgets/scheduling_top_bar.dart';

/// The Manager/HR Scheduling screen — the "Schedule" tab of the HR portal.
///
/// Reproduction of the Figma "Scheduling" group's 3 frames ("Calendar -
/// Scheduling", "Board - Scheduling", "Requests - Scheduling"), which all
/// share the exact same header and segmented tab bar and only swap their
/// main content area — implemented here as a single page with an internal
/// segmented-tab state rather than 3 separate pages.
class SchedulingPage extends StatelessWidget {
  const SchedulingPage({super.key});

  SchedulingController _resolveController() {
    try {
      return Get.find<SchedulingController>();
    } catch (_) {
      return Get.put(GetIt.instance<SchedulingController>(), permanent: true);
    }
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
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _SchedulingError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading the schedule.'
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
                    SchedulingTopBar(onCreateShiftTap: () {}),
                    SchedulingSegmentedTabs(
                      selectedTab: controller.selectedTab.value,
                      requestsBadgeCount: overview.requests.pendingRequests.length,
                      onTabSelected: controller.selectTab,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: switch (controller.selectedTab.value) {
                    SchedulingTab.calendar => CalendarTabView(data: overview.calendar),
                    SchedulingTab.board => BoardTabView(data: overview.board),
                    SchedulingTab.requests => RequestsTabView(data: overview.requests),
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SchedulingError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _SchedulingError({required this.message, required this.onRetry});

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
