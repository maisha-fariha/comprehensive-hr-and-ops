import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/medication_enums.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/entities/schedule_dose.dart';
import '../../domain/repositories/medication_repository.dart';

/// GetX controller for the "Medication MAR" screen.
class MedicationController extends BaseController<MedicationOverview> {
  final MedicationRepository repository;

  final Rx<MedicationTab> selectedTab = MedicationTab.overview.obs;
  final Rx<SchedulePeriod> selectedSchedulePeriod = SchedulePeriod.today.obs;
  final RxBool isExporting = false.obs;

  int _loadGeneration = 0;

  MedicationController({required this.repository}) {
    loadOverview();
  }

  MedicationOverview? get overview => state.value.data;

  Future<void> loadOverview() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getOverview();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  void selectTab(MedicationTab tab) => selectedTab.value = tab;

  void selectSchedulePeriod(SchedulePeriod period) =>
      selectedSchedulePeriod.value = period;

  List<ScheduleDose> dosesForPeriod(List<ScheduleDose> doses) {
    final period = selectedSchedulePeriod.value;
    if (period == SchedulePeriod.today) return doses;
    return doses.where((dose) {
      final hour = dose.scheduledHour;
      if (hour == null) return true;
      return switch (period) {
        SchedulePeriod.morning => hour >= 5 && hour < 12,
        SchedulePeriod.afternoon => hour >= 12 && hour < 17,
        SchedulePeriod.evening => hour >= 17 || hour < 5,
        SchedulePeriod.today => true,
      };
    }).toList();
  }

  /// Web "Export MAR" — CSV of medication administrations.
  Future<void> exportMar() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final result = await repository.exportMarCsv();
      await result.when(
        success: (bytes) async {
          final stamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final fileName = 'mar_administrations-$stamp.csv';
          final saveResult = await MediaStoreDownload.saveFileAndOpen(
            fileName: fileName,
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
      AppSnackbar.show(
        'Could not export MAR',
        error.toString(),
        force: true,
      );
    } finally {
      isExporting.value = false;
    }
  }

  @override
  Future<void> refresh() => loadOverview();
}
