import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/offline/outbox_feature.dart';
import '../../../../../core/offline/presentation/pending_outbox_section.dart';
import '../../../../hr/daily_logs/domain/repositories/daily_logs_repository.dart';
import '../../../../hr/daily_logs/presentation/controllers/daily_logs_controller.dart';
import '../../../../hr/daily_logs/presentation/widgets/new_log_entry_sheet.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../controllers/staff_daily_logs_controller.dart';
import '../widgets/staff_daily_logs_app_bar.dart';
import '../widgets/staff_daily_logs_filters_card.dart';
import '../widgets/staff_daily_logs_queue_tab_view.dart';
import '../widgets/staff_daily_logs_tab_bar.dart';
import '../widgets/staff_house_activity_tab_view.dart';
import '../widgets/staff_resident_day_tab_view.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_refresh_indicator.dart';

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

  /// Web "+ Add Care Note" → New Log Entry modal (not the mobile-only Daily Note).
  Future<void> _openAddCareNote(
    BuildContext context,
    StaffDailyLogsController staff,
  ) async {
    final clientId = staff.selectedClientId.value;
    final residenceId = staff.selectedResidenceId.value;
    if (clientId == null ||
        clientId.isEmpty ||
        residenceId == null ||
        residenceId.isEmpty) {
      return;
    }

    var name = staff.overview?.dayClientName;
    if (name == null || name.isEmpty) {
      for (final r in staff.residentOptions) {
        if (r.id == clientId) {
          name = r.name;
          break;
        }
      }
    }

    final logDate = DailyLogsController.dayKey(staff.toDate.value);
    final entryController = DailyLogsController(
      repository: GetIt.instance<DailyLogsRepository>(),
      session: Get.find<UserSession>(),
    );
    entryController.openDay(
      clientId,
      logDate,
      name: name,
      residence: residenceId,
    );
    entryController.residenceId.value = residenceId;

    await showNewLogEntrySheet(context, controller: entryController);
    await staff.refresh();
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
          final canWriteLog = !Get.isRegistered<UserSession>() ||
              Get.find<UserSession>().can('daily-logs:write');

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
                        singleDateMode: controller.selectedTab.value ==
                            StaffDailyLogsTab.residentDay,
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
              PendingOutboxSection(
                features: const {OutboxFeature.dailyLogs},
                onSynced: () => controller.refresh(),
              ),
              Expanded(
                child: AppRefreshIndicator(
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
                              onItemTap: controller.openDay,
                            ),
                          StaffDailyLogsTab.missing =>
                            StaffDailyLogsQueueTabView(
                              stats: safeOverview.stats,
                              items: controller.filteredMissing,
                              totalCount: safeOverview.missingTotal,
                              sectionTitle: 'Missing',
                              emptyMessage:
                                  'No missing logs for these filters.',
                              onItemTap: controller.openDay,
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
                              onAddCareNote: canWriteLog
                                  ? () => _openAddCareNote(context, controller)
                                  : null,
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
