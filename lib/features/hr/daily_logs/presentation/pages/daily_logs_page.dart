import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_logs_enums.dart';
import '../controllers/daily_logs_controller.dart';
import '../widgets/daily_logs_app_bar.dart';
import '../widgets/daily_logs_tab_bar.dart';
import '../widgets/handover_tab_view.dart';
import '../widgets/missing_tab_view.dart';
import '../widgets/review_tab_view.dart';

/// The "Daily Logs" screen: a single page hosting three segmented tabs
/// (Review / Missing / Handover) that all share the same white app bar and
/// tab-bar header.
///
/// Pixel-accurate reproduction of the Figma "Review - Daily-logs" /
/// "Missing - Daily-logs" / "Handover - Daily-logs" screens (nodes
/// 504:14421, 504:14649, 504:14880) inside the "Manager Mobile Screens"
/// section. Built from reference screenshots (live Figma MCP access was
/// unavailable while this screen was authored - see implementation report).
class DailyLogsPage extends StatelessWidget {
  const DailyLogsPage({super.key});

  DailyLogsController _resolveController() {
    try {
      return Get.find<DailyLogsController>();
    } catch (_) {
      return Get.put(GetIt.instance<DailyLogsController>(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Obx(() {
          final response = controller.state.value;
          final overview = response.data;

          if (overview == null && controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal));
          }

          if (overview == null) {
            return _DailyLogsError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Daily Logs.'
                  : controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          return Column(
            children: [
              const DailyLogsAppBar(),
              DailyLogsTabBar(
                selectedTab: controller.selectedTab.value,
                missingBadgeCount: overview.missingLogs.length,
                onTabSelected: controller.selectTab,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: switch (controller.selectedTab.value) {
                    DailyLogsTab.review => ReviewTabView(
                        stats: overview.reviewStats,
                        submittedLogs: overview.submittedLogs,
                        submittedLogsTotalCount: overview.submittedLogsTotalCount,
                        clientStatusSummaries: overview.clientStatusSummaries,
                      ),
                    DailyLogsTab.missing => MissingTabView(
                        stats: overview.missingStats,
                        missingLogs: overview.missingLogs,
                      ),
                    DailyLogsTab.handover => HandoverTabView(
                        stats: overview.handoverStats,
                        handoverEntries: overview.handoverEntries,
                      ),
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

class _DailyLogsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DailyLogsError({required this.message, required this.onRetry});

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
