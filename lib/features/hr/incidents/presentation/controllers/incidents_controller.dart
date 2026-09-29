import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the Incidents list screen (all 3 tabs).
///
/// Extends the project's [BaseController] (from `gems_data_layer`) so
/// loading/error state is handled the same way as every other feature
/// controller in the app, and additionally owns the selected-tab state
/// backing the "Open / Under Review / Closed" segmented control.
class IncidentsController extends BaseController<IncidentsBoard> {
  final IncidentsRepository repository;

  IncidentsController({required this.repository}) {
    loadBoard();
  }

  final Rx<IncidentsTab> selectedTab = IncidentsTab.open.obs;
  final RxBool isExporting = false.obs;

  IncidentsBoard? get board => state.value.data;

  void selectTab(IncidentsTab tab) => selectedTab.value = tab;

  int _loadGeneration = 0;

  Future<void> loadBoard() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getBoard();
    if (generation != _loadGeneration) return;
    result.when(
      success: setSuccess,
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() => loadBoard();

  /// Web "Export List" — CSV of the incident log.
  Future<void> exportIncidentList() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final result = await repository.exportIncidentListCsv();
      await result.when(
        success: (bytes) async {
          final stamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final fileName = 'incident_log-$stamp.csv';
          final saveResult = await MediaStoreDownload.saveFileAndOpen(
            fileName: fileName,
            bytes: Uint8List.fromList(bytes),
            mimeType: 'text/csv',
            chooserTitle: 'Open CSV',
          );
          if (!saveResult.success) {
            AppSnackbar.show(
              'Could not export list',
              saveResult.error ?? 'Could not save or open the CSV file.',
              force: true,
            );
            return;
          }

          AppSnackbar.show(
            'Export ready',
            'Incident log CSV exported.',
            force: true,
          );
        },
        failure: (error) async {
          AppSnackbar.show(
            'Could not export list',
            error.message,
            force: true,
          );
        },
      );
    } catch (error) {
      AppSnackbar.show(
        'Could not export list',
        error.toString(),
        force: true,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
