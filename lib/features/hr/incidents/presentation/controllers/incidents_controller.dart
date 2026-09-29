import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../team_reports/domain/repositories/team_reports_repository.dart';
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
  static const String incidentLogReportKey = 'incident_log';

  final IncidentsRepository repository;
  final TeamReportsRepository reportsRepository;

  IncidentsController({
    required this.repository,
    TeamReportsRepository? reportsRepository,
  }) : reportsRepository =
            reportsRepository ?? GetIt.instance<TeamReportsRepository>() {
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

  /// Web "Export List" — `POST /reports/exports` with `reportKey: incident_log`.
  Future<void> exportIncidentList() async {
    if (isExporting.value) return;
    isExporting.value = true;

    final create = await reportsRepository.createExport(
      reportKey: incidentLogReportKey,
      format: 'csv',
    );

    final export = create.when(
      success: (item) => item,
      failure: (error) {
        AppSnackbar.show('Could not export list', error.message);
        return null;
      },
    );
    if (export == null) {
      isExporting.value = false;
      return;
    }

    // Poll briefly until ready (web export button does the same).
    var current = export;
    for (var attempt = 0; attempt < 12; attempt++) {
      if (current.isReady) break;
      await Future<void>.delayed(const Duration(milliseconds: 750));
      final status = await reportsRepository.getExportStatus(current.id);
      final next = status.when(
        success: (item) => item,
        failure: (_) => null,
      );
      if (next == null) break;
      current = next;
      if (current.isReady) break;
    }

    if (!current.isReady) {
      isExporting.value = false;
      AppSnackbar.show(
        'Export queued',
        'Incident log export is still processing. Try again in a moment.',
      );
      return;
    }

    final download = await reportsRepository.downloadExportFile(current.id);
    await download.when(
      success: (bytes) async {
        final shortId = current.id.length > 8
            ? current.id.substring(0, 8)
            : current.id;
        final saveResult = await MediaStoreDownload.saveFile(
          fileName: 'incident_log-$shortId.csv',
          bytes: Uint8List.fromList(bytes),
          mimeType: 'text/csv',
        );
        if (saveResult.success) {
          AppSnackbar.show(
            'Export downloaded',
            'Saved to ${saveResult.displayLocation}',
          );
        } else {
          AppSnackbar.show(
            'Could not download',
            saveResult.error ?? 'Could not save the export file.',
          );
        }
      },
      failure: (error) async {
        AppSnackbar.show('Could not download', error.message);
      },
    );

    isExporting.value = false;
  }
}
