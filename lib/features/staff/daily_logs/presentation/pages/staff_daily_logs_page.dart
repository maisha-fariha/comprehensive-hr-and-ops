import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/daily_note_client_info.dart';
import '../../domain/entities/staff_client_log_entry.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../controllers/staff_daily_logs_controller.dart';
import '../widgets/staff_daily_logs_app_bar.dart';
import '../widgets/staff_daily_logs_filters_card.dart';
import '../widgets/staff_daily_logs_queue_tab_view.dart';
import '../widgets/staff_daily_logs_tab_bar.dart';
import '../widgets/staff_house_activity_tab_view.dart';
import '../widgets/staff_resident_day_tab_view.dart';
import 'daily_note_page.dart';

/// Staff Daily Logs — web-parity filters + tabs.
class StaffDailyLogsPage extends StatelessWidget {
  const StaffDailyLogsPage({super.key});

  StaffDailyLogsController _resolveController() {
    try {
      return Get.find<StaffDailyLogsController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<StaffDailyLogsController>(),
        permanent: true,
      );
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
          clientId: entry.clientId,
          residenceId: entry.residenceId,
          entryId: entry.entryId,
        ),
      ),
    );
  }

  void _openNoteForSelected(StaffDailyLogsController controller) {
    final clientId = controller.selectedClientId.value;
    final residenceId = controller.selectedResidenceId.value;
    if (clientId == null || residenceId == null) return;
    var name = controller.overview?.dayClientName;
    if (name == null || name.isEmpty) {
      for (final r in controller.residentOptions) {
        if (r.id == clientId) {
          name = r.name;
          break;
        }
      }
    }
    name ??= 'Resident';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? 'R'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    Get.to(
      () => DailyNotePage(
        client: DailyNoteClientInfo(
          initials: initials,
          name: name!,
          dobLabel: '',
          roomLabel: '',
          clientId: clientId,
          residenceId: residenceId,
        ),
      ),
    );
  }

  void _onBack() {
    Get.offAll(() => const StaffShell(initialIndex: 0));
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
          final residenceId = controller.selectedResidenceId.value;
          final hasResidence = residenceId != null && residenceId.isNotEmpty;

          if (overview == null &&
              controller.isLoading.value &&
              hasResidence) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            );
          }

          if (overview == null &&
              controller.errorMessage.value.isNotEmpty &&
              hasResidence) {
            return _StaffDailyLogsError(
              message: controller.errorMessage.value,
              onRetry: controller.refresh,
            );
          }

          final safeOverview = overview ?? StaffDailyLogsOverview.empty;

          return Column(
            children: [
              ColoredBox(
                color: AppColors.surfaceWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StaffDailyLogsAppBar(onBack: _onBack),
                    Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 16,
                        bottom: 8,
                      ),
                      child: StaffDailyLogsFiltersCard(
                        residenceId: controller.selectedResidenceId.value,
                        clientId: controller.selectedClientId.value,
                        fromDate: controller.fromDate.value,
                        toDate: controller.toDate.value,
                        residences: controller.residenceOptions.toList(),
                        residents: controller.residentOptions,
                        onResidenceChanged: controller.setResidence,
                        onResidentChanged: controller.setResident,
                        onFromChanged: controller.setFromDate,
                        onToChanged: controller.setToDate,
                        formatDate: controller.formatFilterDate,
                      ),
                    ),
                    StaffDailyLogsTabBar(
                      selectedTab: controller.selectedTab.value,
                      onTabSelected: controller.selectTab,
                      toReviewCount: safeOverview.toReviewTotal,
                      missingCount: safeOverview.missingTotal,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: controller.refresh,
                  child: !hasResidence
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            _ChooseResidenceEmpty(),
                          ],
                        )
                      : switch (controller.selectedTab.value) {
                          StaffDailyLogsTab.toReview =>
                            StaffDailyLogsQueueTabView(
                              stats: safeOverview.stats,
                              items: controller.filteredToReview,
                              totalCount: safeOverview.toReviewTotal,
                              sectionTitle: 'To review',
                              emptyMessage:
                                  'No logs awaiting review for these filters.',
                              onItemTap: _openDailyNote,
                            ),
                          StaffDailyLogsTab.missing =>
                            StaffDailyLogsQueueTabView(
                              stats: safeOverview.stats,
                              items: controller.filteredMissing,
                              totalCount: safeOverview.missingTotal,
                              sectionTitle: 'Missing',
                              emptyMessage:
                                  'No missing logs for these filters.',
                              onItemTap: _openDailyNote,
                            ),
                          StaffDailyLogsTab.residentDay =>
                            StaffResidentDayTabView(
                              hasResidence: true,
                              hasResident:
                                  (controller.selectedClientId.value ?? '')
                                      .isNotEmpty,
                              clientName: safeOverview.dayClientName,
                              dateLabel: safeOverview.dayLogDateLabel,
                              entries: safeOverview.dayEntries,
                              onWriteNote: () =>
                                  _openNoteForSelected(controller),
                            ),
                          StaffDailyLogsTab.houseActivity =>
                            StaffHouseActivityTabView(
                              hasResidence: true,
                              activities: safeOverview.houseActivities,
                              totalCount: safeOverview.houseActivitiesTotal,
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

class _ChooseResidenceEmpty extends StatelessWidget {
  const _ChooseResidenceEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Choose a residence to begin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Daily logs are read one residence at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textMuted,
            ),
          ),
        ],
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.criticalRed,
              size: 40,
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
