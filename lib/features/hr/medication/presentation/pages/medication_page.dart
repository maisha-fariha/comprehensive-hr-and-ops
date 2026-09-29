import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../hr_shell.dart';
import '../../../presentation/widgets/hr_bottom_nav_bar.dart';
import '../../../../staff/medication/domain/entities/staff_medication_enums.dart';
import '../../../../staff/medication/presentation/controllers/staff_medication_controller.dart';
import '../../../../staff/medication/presentation/widgets/given_tab_view.dart';
import '../../../../staff/medication/presentation/widgets/mar_registry_tab_view.dart';
import '../../../../staff/medication/presentation/widgets/prn_registry_tab_view.dart';
import '../../../../staff/medication/presentation/widgets/resident_chart_tab_view.dart';
import '../../../../staff/medication/presentation/widgets/staff_client_medications_sheet.dart';
import '../../../../staff/medication/presentation/widgets/staff_mar_metrics_row.dart';
import '../../../../staff/medication/presentation/widgets/staff_medication_metrics_strip.dart';
import '../../../../staff/medication/presentation/widgets/staff_medication_tab_bar.dart';
import '../../domain/repositories/medication_repository.dart';
import '../widgets/medication_header.dart';

/// Manager Medication MAR — web `/dashboard/medication` parity:
/// metrics, Due Now / Missed side cards, Export MAR, and
/// MAR / PRN / Given / Resident chart tabs (same console as staff web).
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  static const int _moreTabIndex = 4;

  late final StaffMedicationController _controller;
  final RxBool _isExporting = false.obs;

  @override
  void initState() {
    super.initState();
    _controller = _resolveController();
  }

  StaffMedicationController _resolveController() {
    try {
      final existing = Get.find<StaffMedicationController>();
      existing.refresh();
      return existing;
    } catch (_) {
      return Get.put(
        GetIt.instance<StaffMedicationController>(),
        permanent: true,
      );
    }
  }

  void _onBottomNavTap(int index) {
    Get.offAll(() => HrShell(initialIndex: index));
  }

  Future<void> _exportMar() async {
    if (_isExporting.value) return;
    _isExporting.value = true;
    try {
      final repository = GetIt.instance<MedicationRepository>();
      final result = await repository.exportMarCsv();
      await result.when(
        success: (bytes) async {
          final stamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final saveResult = await MediaStoreDownload.saveFileAndOpen(
            fileName: 'mar_administrations-$stamp.csv',
            bytes: Uint8List.fromList(bytes),
            mimeType: 'text/csv',
            chooserTitle: 'Open CSV',
          );
          if (!saveResult.success) {
            AppSnackbar.show(
              'Could not export MAR',
              saveResult.error ?? 'Could not save or open the CSV file.',
              force: true,
            );
            return;
          }
          AppSnackbar.show(
            'Export ready',
            'MAR administrations CSV exported.',
            force: true,
          );
        },
        failure: (error) async {
          AppSnackbar.show(
            'Could not export MAR',
            error.message,
            force: true,
          );
        },
      );
    } catch (error) {
      AppSnackbar.show('Could not export MAR', error.toString(), force: true);
    } finally {
      _isExporting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = Get.find<UserSession>().canWriteMar;
    final canPrn = Get.find<UserSession>().canAdministerMarDose(isPrn: true);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: Obx(
        () => HrBottomNavBar(
          currentIndex: _moreTabIndex,
          onTap: _onBottomNavTap,
          alertsBadgeCount: hrAlertsBadgeCount(),
        ),
      ),
      body: Obx(() {
        final response = _controller.state.value;
        final overview = response.data;

        if (overview == null && _controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondaryTeal),
          );
        }

        if (overview == null) {
          return _MedicationError(
            message: _controller.errorMessage.value.isEmpty
                ? 'Something went wrong while loading medications.'
                : _controller.errorMessage.value,
            onRetry: _controller.refresh,
          );
        }

        return Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MedicationHeader(
                    title: 'Medication Administration Record (MAR)',
                    subtitle: 'Across residences · MAR console',
                    onBackTap: Get.back,
                    isExporting: _isExporting.value,
                    onExportTap: _exportMar,
                  ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 8,
                    ),
                    child: StaffMarMetricsRow(overview: overview),
                  ),
                  if (canWrite)
                    StaffMedicationActionRow(
                      canWrite: canWrite,
                      onRecordAdministration: () =>
                          _controller.startRecordAdministration(context),
                      onAddMedicine: () =>
                          _controller.openAddMedicine(context),
                    ),
                  Padding(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 16,
                      top: 4,
                      bottom: 8,
                    ),
                    child: StaffMedicationTabBar(
                      key: const Key('hr-mar-section-nav'),
                      selectedTab: _controller.selectedTab.value,
                      marCount: _controller.marTabCount,
                      prnCount: _controller.prnTabCount,
                      givenCount: _controller.givenTabCount,
                      onTabSelected: _controller.selectTab,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondaryTeal,
                onRefresh: _controller.refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 4),
                    ResponsiveHelper.getResponsiveWidth(context, 16),
                    ResponsiveHelper.getResponsiveHeight(context, 32),
                  ),
                  children: [
                    switch (_controller.selectedTab.value) {
                      StaffMedicationTab.mar => MarRegistryTabView(
                          doses: _controller.filteredScheduledDoses,
                          scheduledCount: overview.scheduledCount,
                          searchController: _controller.searchController,
                          residenceId: _controller.filterResidenceId.value,
                          clientId: _controller.filterClientId.value,
                          medication: _controller.filterMedication.value,
                          state: _controller.filterState.value,
                          residenceOptions:
                              _controller.residenceFilterOptions,
                          residentOptions: _controller.residentFilterOptions,
                          medicationOptions:
                              _controller.medicationFilterOptions,
                          hasActiveFilters: _controller.hasActiveFilters,
                          onSearchChanged: (v) =>
                              _controller.updateFilters(search: v),
                          onFilterChanged: _controller.updateFilters,
                          onClearFilters: _controller.clearFilters,
                          canWriteScheduled: canWrite,
                          canWritePrn: canPrn,
                          onAdminister: _controller.markAdministered,
                          onNotGiven: _controller.markNotGiven,
                          onOpenClientMedications: (dose) {
                            showStaffClientMedicationsSheet(
                              context,
                              clientId: dose.clientId,
                              clientName: dose.residentName,
                            );
                          },
                        ),
                      StaffMedicationTab.prn => PrnRegistryTabView(
                          items: _controller.prnItems.toList(),
                          canGive: canPrn,
                          onGive: _controller.givePrn,
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
                          doses: _controller.givenItems.toList(),
                        ),
                      StaffMedicationTab.residentChart =>
                        ResidentChartTabView(
                          clients: _controller.chartClients.toList(),
                          loading: _controller.loadingExtras.value &&
                              _controller.chartClients.isEmpty,
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
                      onReviewAllMissed: _controller.reviewAllMissed,
                      onChartDue: canWrite
                          ? (dose) => _controller.markAdministered(dose.id)
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
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
