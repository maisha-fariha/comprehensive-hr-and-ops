import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/offline/offline_outbox.dart';
import '../../../../../core/offline/outbox_feature.dart';
import '../../../../../core/offline/presentation/pending_outbox_section.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../extras/presentation/pages/staff_residences_page.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import '../../domain/entities/staff_medication_enums.dart';
import '../controllers/staff_medication_controller.dart';
import '../widgets/given_tab_view.dart';
import '../widgets/mar_registry_tab_view.dart';
import '../widgets/prn_registry_tab_view.dart';
import '../widgets/resident_chart_tab_view.dart';
import '../widgets/staff_client_medications_sheet.dart';
import '../widgets/staff_medication_header.dart';
import '../widgets/staff_medication_metrics_strip.dart';
import '../widgets/staff_mar_filters_bar.dart';
import '../widgets/staff_medication_tab_bar.dart';
import '../widgets/staff_mar_metrics_row.dart';

/// Staff Medication MAR — web console parity:
/// metrics + MAR / PRN / Given / Resident chart tabs.
class StaffMedicationPage extends StatelessWidget {
  static const int _marTasksTabIndex = 3;

  const StaffMedicationPage({super.key});

  StaffMedicationController _resolveController() {
    try {
      return Get.find<StaffMedicationController>();
    } catch (_) {
      return Get.put(
        GetIt.instance<StaffMedicationController>(),
        permanent: true,
      );
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => StaffShell(initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _resolveController();
    final canWrite = Get.find<UserSession>().canWriteMar;
    final canPrn = Get.find<UserSession>().canAdministerMarDose(isPrn: true);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: _marTasksTabIndex,
        onTap: _onBottomNavTap,
      ),
      body: Obx(() {
        final response = controller.state.value;
        final overview = response.data;
        OfflineOutbox.maybe?.store.items.length;

        if (overview == null && controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
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
                      top: 4,
                      bottom: 8,
                    ),
                    child: StaffMarMetricsRow(overview: overview),
                  ),
                  StaffMedicationActionRow(
                    canWrite: canWrite,
                    onRecordAdministration: () =>
                        controller.startRecordAdministration(context),
                    onAddMedicine: () => controller.openAddMedicine(context),
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 8,
                    ),
                    child: StaffMedicationTabBar(
                      selectedTab: controller.selectedTab.value,
                      marCount: controller.marTabCount,
                      prnCount: controller.prnTabCount,
                      givenCount: controller.givenTabCount,
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
                    PendingOutboxSection(
                      features: const {
                        OutboxFeature.mar,
                        OutboxFeature.medications,
                      },
                      onSynced: () => controller.refresh(),
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                    ),
                    switch (controller.selectedTab.value) {
                      StaffMedicationTab.mar => MarRegistryTabView(
                          doses: controller.filteredScheduledDoses,
                          scheduledCount: controller.marTabCount,
                          searchController: controller.searchController,
                          residenceId: controller.filterResidenceId.value,
                          clientId: controller.filterClientId.value,
                          medication: controller.filterMedication.value,
                          state: controller.filterState.value,
                          residenceOptions: controller.residenceFilterOptions,
                          residentOptions: controller.residentFilterOptions,
                          medicationOptions:
                              controller.medicationFilterOptions,
                          hasActiveFilters: controller.hasActiveFilters,
                          onSearchChanged: (v) =>
                              controller.updateFilters(search: v),
                          onFilterChanged: controller.updateFilters,
                          onClearFilters: controller.clearFilters,
                          canWriteScheduled: canWrite,
                          canWritePrn: canPrn,
                          onAdminister: controller.markAdministered,
                          onNotGiven: controller.markNotGiven,
                          onEdit: controller.canEditMedicines
                              ? (dose) => controller.editDose(context, dose)
                              : null,
                          administeredByName: controller.administeredByName,
                          isPendingSync: controller.isPendingSync,
                          onOpenClientMedications: (dose) {
                            showStaffClientMedicationsSheet(
                              context,
                              clientId: dose.clientId,
                              clientName: dose.residentName,
                            );
                          },
                        ),
                      StaffMedicationTab.prn => PrnRegistryTabView(
                          items: controller.filteredPrnItems,
                          filters: StaffMarFiltersBar(
                            searchController: controller.searchController,
                            residenceId: controller.filterResidenceId.value,
                            clientId: controller.filterClientId.value,
                            medication: controller.filterMedication.value,
                            state: controller.filterState.value,
                            residenceOptions:
                                controller.residenceFilterOptions,
                            residentOptions: controller.residentFilterOptions,
                            medicationOptions:
                                controller.medicationFilterOptions,
                            hasActiveFilters: controller.hasActiveFilters,
                            onSearchChanged: (v) =>
                                controller.updateFilters(search: v),
                            onFilterChanged: controller.updateFilters,
                            onClear: controller.clearFilters,
                          ),
                          canGive: canPrn,
                          onEdit: controller.canEditMedicines
                              ? (item) =>
                                  controller.editMedication(context, item)
                              : null,
                          onGive: controller.givePrn,
                          onOpenChart: (item) {
                            if (item.clientId.isEmpty) return;
                            showStaffClientMedicationsSheet(
                              context,
                              clientId: item.clientId,
                              clientName: item.clientName.isEmpty
                                  ? 'Resident'
                                  : item.clientName,
                            );
                          },
                        ),
                      StaffMedicationTab.given => GivenTabView(
                          doses: controller.givenItems.toList(),
                        ),
                      StaffMedicationTab.residentChart =>
                        ResidentChartTabView(
                          clients: controller.chartClients.toList(),
                          loading: controller.loadingExtras.value &&
                              controller.chartClients.isEmpty,
                          onOpenChart: (client) {
                            showStaffClientMedicationsSheet(
                              context,
                              clientId: client.id,
                              clientName: client.name,
                            );
                          },
                        ),
                    },
                    StaffMedicationSideCards(
                      overview: overview,
                      onReviewAllMissed: controller.reviewAllMissed,
                      onChartDue: canWrite
                          ? (dose) => controller.markAdministered(dose.id)
                          : null,
                    ),
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

  bool get _isNoResidence => message.toLowerCase().contains('residence');

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
            if (_isNoResidence) ...[
              ElevatedButton(
                key: const Key('staff-mar-view-residence'),
                onPressed: () => Get.to(() => const StaffResidencesPage()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(
                    ResponsiveHelper.getResponsiveWidth(context, 200),
                    ResponsiveHelper.getResponsiveHeight(context, 44),
                  ),
                ),
                child: const Text('View Residence'),
              ),
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 10),
              ),
            ],
            ElevatedButton(
              key: const Key('staff-mar-retry'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNoResidence
                    ? AppColors.surfaceWhite
                    : AppColors.secondaryTeal,
                foregroundColor:
                    _isNoResidence ? AppColors.secondaryTeal : Colors.white,
                side: _isNoResidence
                    ? const BorderSide(color: AppColors.secondaryTeal)
                    : BorderSide.none,
                minimumSize: Size(
                  ResponsiveHelper.getResponsiveWidth(context, 200),
                  ResponsiveHelper.getResponsiveHeight(context, 44),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
