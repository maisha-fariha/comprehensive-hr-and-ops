import 'dart:typed_data';

import 'package:gems_core/gems_core.dart';
import 'package:gems_data_layer/gems_data_layer.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/residence_form.dart';
import '../../domain/entities/residence_summary.dart';
import '../../domain/repositories/residences_repository.dart';

/// Saves exported CSV bytes; returns an error message or null.
typedef ResidenceExportSaver = Future<String?> Function(
  List<int> bytes,
  String fileName,
);

/// Web `/dashboard/residences` ("Residences Management"): KPI tiles, server
/// search / filters / pagination, the row Actions menu, the Add/Edit wizard
/// and "Export List".
class ResidencesController extends BaseController<List<ResidenceSummary>> {
  final ResidencesRepository repository;
  final ResidenceAdminRepository? admin;
  final UserSession? _session;
  final ResidenceExportSaver _saveExport;

  static const List<int> pageSizes = [10, 25, 50];

  final RxString query = ''.obs;

  /// `null` means "All statuses" / "All types".
  final RxnString statusFilter = RxnString();
  final RxnString typeFilter = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = pageSizes.first.obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 1.obs;
  final Rxn<ResidencesKpis> kpis = Rxn<ResidencesKpis>();
  final Rx<ResidenceTenantContext> tenant =
      const ResidenceTenantContext().obs;
  final RxBool exporting = false.obs;
  final RxnString busyId = RxnString();

  int _loadGeneration = 0;
  List<ResidenceSummary> _legacyAll = const [];
  late final Worker _searchWorker;

  ResidencesController({
    required this.repository,
    ResidenceAdminRepository? admin,
    UserSession? session,
    ResidenceExportSaver? saveExport,
  })  : admin = admin ??
            (repository is ResidenceAdminRepository
                ? repository as ResidenceAdminRepository
                : null),
        _session = session,
        _saveExport = saveExport ?? _saveWithMediaStore {
    _searchWorker = debounce<String>(
      query,
      (_) {
        page.value = 1;
        loadResidences();
      },
      time: const Duration(milliseconds: 350),
    );
    loadResidences();
    _loadTenant();
  }

  bool can(String permission) => _session?.can(permission) ?? true;

  bool get canCreate => can('residences:create');
  bool get canUpdate => can('residences:update');

  /// Web: Delete sits behind both `residences:update` and `residences:delete`.
  bool get canDelete => canUpdate && can('residences:delete');
  bool get canExport => can('residences:export');

  List<ResidenceSummary> get residences => state.value.data ?? const [];

  /// Web `X`: the larger of the summary count, the total and the rows.
  int get residenceCount {
    final fromSummary = kpis.value?.residences ?? 0;
    return [fromSummary, total.value, residences.length]
        .reduce((a, b) => a > b ? a : b);
  }

  int? get residenceLimit => tenant.value.residenceLimit;

  bool get limitReached =>
      residenceLimit != null && residenceCount >= residenceLimit!;

  String get limitTooltip =>
      'Plan limit reached ($residenceCount/$residenceLimit residences). '
      'Upgrade your plan to add more.';

  bool get hasFilters =>
      query.value.trim().isNotEmpty ||
      statusFilter.value != null ||
      typeFilter.value != null;

  /// Web: type options are the distinct types on the rows shown.
  List<String> get types {
    final set = residences
        .map((r) => r.residenceType)
        .whereType<String>()
        .toSet();
    if (typeFilter.value != null) set.add(typeFilter.value!);
    return set.toList()..sort();
  }

  /// Kept for callers that filter locally; the list is filtered server-side.
  List<ResidenceSummary> get filtered => residences;

  Future<void> loadResidences() async {
    final generation = ++_loadGeneration;
    setLoading(true);
    final result = admin == null ? await _legacyPage() : await _serverPage();
    if (generation != _loadGeneration) return;
    result.when(
      success: (data) {
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        kpis.value = data.summary;
        setSuccess(data.items);
      },
      failure: (error) => setError(error.message),
    );
    setLoading(false);
  }

  Future<Result<ResidencesPageData>> _serverPage() => admin!.listResidences(
        page: page.value,
        limit: limit.value,
        search: query.value,
        status: statusFilter.value,
        residenceType: typeFilter.value,
      );

  Future<Result<ResidencesPageData>> _legacyPage() async {
    final result = await repository.getResidences();
    return result.when(
      success: (all) {
        _legacyAll = all;
        final q = query.value.trim().toLowerCase();
        final rows = all.where((r) {
          if (statusFilter.value != null && r.status != statusFilter.value) {
            return false;
          }
          if (typeFilter.value != null &&
              r.residenceType != typeFilter.value) {
            return false;
          }
          return q.isEmpty ||
              r.name.toLowerCase().contains(q) ||
              (r.primaryManager?.name.toLowerCase().contains(q) ?? false);
        }).toList();
        final start = ((page.value - 1) * limit.value).clamp(0, rows.length);
        final end = (start + limit.value).clamp(0, rows.length);
        return Result.success(
          ResidencesPageData(
            items: rows.sublist(start, end),
            total: rows.length,
            totalPages: (rows.length + limit.value - 1) ~/ limit.value,
            summary: ResidencesKpis(
              residences: rows.length,
              active: rows.where((r) => r.isActive).length,
              residents: rows.fold(0, (s, r) => s + r.residents),
              beds: rows.fold(0, (s, r) => s + r.bedCapacity),
              bedsFree: rows.fold(0, (s, r) => s + r.bedsFree),
              atCapacity: rows.where((r) => r.atCapacity).length,
            ),
          ),
        );
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<void> _loadTenant() async {
    final repo = admin;
    if (repo == null) return;
    final result = await repo.getTenantContext();
    result.when(success: (t) => tenant.value = t, failure: (_) {});
  }

  void setStatusFilter(String? value) {
    statusFilter.value = value;
    page.value = 1;
    loadResidences();
  }

  void setTypeFilter(String? value) {
    typeFilter.value = value;
    page.value = 1;
    loadResidences();
  }

  void setPage(int value) {
    page.value = value;
    loadResidences();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    loadResidences();
  }

  /// The residence as loaded in the list, used to seed the Edit wizard.
  ResidenceSummary? rowById(String id) {
    for (final r in [...residences, ..._legacyAll]) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<List<ResidenceRoom>?> loadRooms(String residenceId) async {
    final result = await repository.getRooms(residenceId);
    return result.when(success: (rooms) => rooms, failure: (_) => null);
  }

  /// Actions menu "Take out of service" / "Activate".
  Future<void> setResidenceStatus(ResidenceSummary r, String status) async {
    final repo = admin;
    if (repo == null) return;
    busyId.value = r.id;
    final result = await repo.setStatus(r.id, status);
    busyId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show(
          status == 'active'
              ? '${r.name} is now active'
              : '${r.name} is out of service and hidden from staff',
          '',
        );
        loadResidences();
      },
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  /// Actions menu "Delete" (after the confirm dialog). True on success.
  Future<bool> deleteResidence(ResidenceSummary r) async {
    final repo = admin;
    if (repo == null) return false;
    busyId.value = r.id;
    final result = await repo.deleteResidence(r.id);
    busyId.value = null;
    return result.when(
      success: (_) {
        AppSnackbar.show('Residence deleted', '');
        loadResidences();
        return true;
      },
      failure: (error) {
        AppSnackbar.show(error.message, '');
        return false;
      },
    );
  }

  /// Wizard submit (web `et`). Edit sends assignments only when they
  /// changed unless [alwaysSendAssignments] (the detail drawer's edit).
  /// Returns an error message, or null on success.
  Future<String?> submitResidence(
    ResidenceFormValues values, {
    ResidenceSummary? editing,
    bool alwaysSendAssignments = false,
  }) async {
    final repo = admin;
    if (repo == null) return 'Failed to save residence';
    final assignments = values.toAssignments();
    if (editing != null) {
      final before = ResidenceFormValues.fromResidence(editing).toAssignments();
      final unchanged =
          ResidenceFormValues.sameAssignments(before, assignments);
      final result = await repo.updateResidence(
        editing.id,
        values.toBody(),
        assignments: alwaysSendAssignments || !unchanged ? assignments : null,
      );
      return result.when(
        success: (_) {
          AppSnackbar.show('Residence updated', '');
          loadResidences();
          return null;
        },
        failure: (error) => error.message,
      );
    }
    final result = await repo.createResidence(values.toBody(), assignments);
    return result.when(
      success: (_) {
        AppSnackbar.show('Residence added', '');
        loadResidences();
        return null;
      },
      failure: (error) => error.message,
    );
  }

  /// Header "Export List" (`reportKey: residence_roster`).
  Future<void> exportList() async {
    final repo = admin;
    if (repo == null || exporting.value) return;
    exporting.value = true;
    try {
      final result = await repo.exportRoster();
      await result.when(
        success: (bytes) async {
          final error = await _saveExport(bytes, 'residence_roster.csv');
          AppSnackbar.show(error ?? 'Export ready', '', force: true);
        },
        failure: (error) async =>
            AppSnackbar.show(error.message, '', force: true),
      );
    } finally {
      exporting.value = false;
    }
  }

  static Future<String?> _saveWithMediaStore(
    List<int> bytes,
    String fileName,
  ) async {
    final saved = await MediaStoreDownload.saveFileAndOpen(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      chooserTitle: 'Open CSV',
    );
    return saved.success
        ? null
        : (saved.error ?? 'Could not save or open the CSV file.');
  }

  @override
  Future<void> refresh() => loadResidences();

  @override
  void onClose() {
    _searchWorker.dispose();
    super.onClose();
  }
}
