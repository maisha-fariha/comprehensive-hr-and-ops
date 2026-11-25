import 'dart:typed_data';

import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/incident_client_option.dart';
import '../../domain/entities/incident_residence_option.dart';
import '../../domain/entities/incident_staff_option.dart';
import '../../domain/entities/incidents_board.dart';
import '../../domain/entities/incidents_enums.dart';
import '../../domain/repositories/incidents_repository.dart';

/// GetX controller for the Incidents list screen.
///
/// Web-parity filters: All / Reported by Me, Any Status, severity, residence,
/// resident, investigator, date range — same query keys as web Incident Reports.
class IncidentsController extends BaseController<IncidentsBoard> {
  final IncidentsRepository repository;

  IncidentsController({required this.repository});

  final RxBool isExporting = false.obs;

  /// Web "Reported by Me" scope (`reporter=me`).
  final RxBool reportedByMe = false.obs;

  /// Web Any Status dropdown (`open` / `investigating` / `closed`).
  final Rxn<IncidentListStatus> statusFilter = Rxn<IncidentListStatus>();
  final Rxn<IncidentSeverity> severityFilter = Rxn<IncidentSeverity>();
  final RxnString residenceFilterId = RxnString();
  final RxnString clientFilterId = RxnString();
  final RxnString investigatorFilterId = RxnString();
  final Rxn<DateTime> fromDate = Rxn<DateTime>();
  final Rxn<DateTime> toDate = Rxn<DateTime>();

  final RxList<IncidentResidenceOption> residences =
      <IncidentResidenceOption>[].obs;
  final RxList<IncidentClientOption> clients = <IncidentClientOption>[].obs;
  final RxList<IncidentClientOption> _allClients =
      <IncidentClientOption>[].obs;
  final RxList<IncidentStaffOption> investigators =
      <IncidentStaffOption>[].obs;

  /// Lightweight Alerts-tab badge (summary only — not the full board).
  final RxnInt badgeOpenCount = RxnInt();
  bool _badgeLoading = false;
  bool _optionsLoading = false;

  IncidentsBoard? get board => state.value.data;

  int _loadGeneration = 0;

  /// Call from the Alerts tab page — loads the full 4-request board once.
  void ensureLoaded() {
    if (board != null || isLoading.value) return;
    loadFilterOptions();
    loadBoard();
  }

  /// Shell badge: one `GET /incidents/summary` (coalesced), never the board.
  void ensureBadge() {
    if (badgeOpenCount.value != null || _badgeLoading) return;
    _badgeLoading = true;
    repository.getOpenCount().then((result) {
      _badgeLoading = false;
      result.when(
        success: (count) => badgeOpenCount.value = count,
        failure: (_) {
          if (badgeOpenCount.value == null) badgeOpenCount.value = 0;
        },
      );
    });
  }

  Future<void> loadFilterOptions() async {
    if (_optionsLoading) return;
    _optionsLoading = true;
    final residencesResult = await repository.getResidences();
    final clientsResult = await repository.searchClients('');
    final staffResult = await repository.getStaff();
    _optionsLoading = false;

    residencesResult.when(
      success: residences.assignAll,
      failure: (_) {},
    );
    clientsResult.when(
      success: (list) {
        _allClients.assignAll(list);
        _applyClientResidenceFilter();
      },
      failure: (_) {},
    );
    staffResult.when(
      success: investigators.assignAll,
      failure: (_) {},
    );
  }

  void _applyClientResidenceFilter() {
    final residenceId = residenceFilterId.value;
    if (residenceId == null || residenceId.isEmpty) {
      clients.assignAll(_allClients);
      return;
    }
    clients.assignAll(
      _allClients.where((c) => c.residenceId == residenceId).toList(),
    );
  }

  void setReportedByMe(bool value) {
    if (reportedByMe.value == value) return;
    reportedByMe.value = value;
    loadBoard();
  }

  void setStatusFilter(IncidentListStatus? value) {
    statusFilter.value = value;
    loadBoard();
  }

  void setSeverityFilter(IncidentSeverity? value) {
    severityFilter.value = value;
    loadBoard();
  }

  Future<void> setResidenceFilter(String? residenceId) async {
    final next =
        (residenceId == null || residenceId.isEmpty) ? null : residenceId;
    residenceFilterId.value = next;
    clientFilterId.value = null;
    _applyClientResidenceFilter();
    loadBoard();
  }

  void setClientFilter(String? clientId) {
    clientFilterId.value =
        (clientId == null || clientId.isEmpty) ? null : clientId;
    loadBoard();
  }

  void setInvestigatorFilter(String? investigatorId) {
    investigatorFilterId.value =
        (investigatorId == null || investigatorId.isEmpty)
            ? null
            : investigatorId;
    loadBoard();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    fromDate.value = from;
    toDate.value = to;
    loadBoard();
  }

  void setFromDate(DateTime? value) {
    fromDate.value = value;
    loadBoard();
  }

  void setToDate(DateTime? value) {
    toDate.value = value;
    loadBoard();
  }

  void clearFilters() {
    // Matches web Clear filters: resets filterKeys only, not All/Reported-by-Me.
    statusFilter.value = null;
    severityFilter.value = null;
    residenceFilterId.value = null;
    clientFilterId.value = null;
    investigatorFilterId.value = null;
    fromDate.value = null;
    toDate.value = null;
    _applyClientResidenceFilter();
    loadBoard();
  }

  static String? _ymd(DateTime? date) {
    if (date == null) return null;
    final local = IsoDateRange.startOfLocalDay(date);
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  Future<void> loadBoard() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = await repository.getBoard(
      status: statusFilter.value?.apiValue,
      severity: severityFilter.value?.name,
      residenceId: residenceFilterId.value,
      clientId: clientFilterId.value,
      investigatorId: investigatorFilterId.value,
      from: _ymd(fromDate.value),
      to: _ymd(toDate.value),
      reportedByMe: reportedByMe.value,
    );
    if (generation != _loadGeneration) return;
    result.when(
      success: (data) {
        setSuccess(data);
        badgeOpenCount.value = data.open.activeCount;
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  @override
  Future<void> refresh() async {
    await Future.wait([
      loadFilterOptions(),
      loadBoard(),
    ]);
  }

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
