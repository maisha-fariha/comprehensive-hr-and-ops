import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../controllers/staff_daily_logs_controller.dart';
import '../widgets/in_progress_tab_view.dart';
import '../widgets/my_clients_tab_view.dart';
import '../widgets/staff_daily_logs_app_bar.dart';
import '../widgets/staff_daily_logs_tab_bar.dart';
import '../widgets/submitted_tab_view.dart';
import 'daily_note_page.dart';

/// The Staff "Daily Logs" screen: a single page hosting three segmented
/// tabs (My Clients / In Progress / Submitted) that all share the same
/// white app bar and tab-bar header.
///
/// Pixel-accurate reproduction of the "My Clients - Daily Logs" /
/// "In Progress - Daily Logs" / "Submitted - Daily Logs" reference
/// screenshots. Built from reference screenshots (live Figma MCP access
/// was unavailable while this screen was authored - see implementation
/// report).
class StaffDailyLogsPage extends StatelessWidget {
  const StaffDailyLogsPage({super.key});

  StaffDailyLogsController _resolveController() {
    try {
      return Get.find<StaffDailyLogsController>();
    } catch (_) {
      return Get.put(GetIt.instance<StaffDailyLogsController>(), permanent: true);
    }
  }

  void _openDailyNote(StaffClientLogEntry entry) {
    Get.to(
      () => DailyNotePage(
        client: DailyNoteClientInfo(
          initials: entry.initials,
          name: entry.clientName,
          dobLabel: entry.dobLabel,
          roomLabel: entry.roomLabel,
        ),
      ),
    );
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
            return _StaffDailyLogsError(
              message: controller.errorMessage.value.isEmpty
                  ? 'Something went wrong while loading Daily Logs.'
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
                    const StaffDailyLogsAppBar(),
                    StaffDailyLogsTabBar(
                      selectedTab: controller.selectedTab.value,
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
                    StaffDailyLogsTab.myClients => MyClientsTabView(
                        stats: overview.stats,
                        myClients: overview.myClients,
                        myClientsTotalCount: overview.myClientsTotalCount,
                        onClientTap: _openDailyNote,
                      ),
                    StaffDailyLogsTab.inProgress => InProgressTabView(
                        stats: overview.stats,
                        inProgressClients: overview.inProgressClients,
                        onClientTap: _openDailyNote,
                      ),
                    StaffDailyLogsTab.submitted => SubmittedTabView(
                        stats: overview.stats,
                        submittedClients: overview.submittedClients,
                        submittedTotalCount: overview.submittedTotalCount,
                        onClientTap: _openDailyNote,
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

class _StaffDailyLogsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StaffDailyLogsError({required this.message, required this.onRetry});

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
