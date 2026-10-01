import 'dart:async';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/hr_document.dart';
import '../../domain/entities/hr_document_draft.dart';
import '../../domain/entities/hr_document_row.dart';
import '../../domain/repositories/hr_documents_repository.dart';
import '../hr_document_files.dart';

/// Web `/dashboard/documents`: registry filters and paging, the summary KPIs,
/// categories and compliance alerts, and every document / type action.
class HrDocumentsController extends GetxController {
  final HrDocumentsRepository repository;
  final UserSession session;
  final Future<HrPickedFile?> Function() pickFile;
  final Future<void> Function(HrDocumentFile file) openFile;
  final DateTime Function() _now;

  HrDocumentsController({
    required this.repository,
    required this.session,
    Future<HrPickedFile?> Function()? pickFile,
    Future<void> Function(HrDocumentFile file)? openFile,
    DateTime Function()? now,
  })  : pickFile = pickFile ?? HrDocumentFiles.pick,
        openFile = openFile ?? HrDocumentFiles.open,
        _now = now ?? DateTime.now;

  static const List<int> pageSizes = [10, 25, 50];
  static const int defaultLimit = 20;
  static const Duration searchDebounce = Duration(milliseconds: 300);

  final RxList<HrDocument> documents = <HrDocument>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  final Rxn<HrDocumentsSummary> summary = Rxn<HrDocumentsSummary>();
  final RxList<HrDocumentType> types = <HrDocumentType>[].obs;
  final RxMap<String, List<HrDocumentOwner>> directories =
      <String, List<HrDocumentOwner>>{}.obs;

  final RxString searchInput = ''.obs;
  final Rx<HrDocumentFilters> filters = const HrDocumentFilters().obs;
  final RxInt page = 1.obs;
  final RxInt limit = defaultLimit.obs;
  final RxnString busyId = RxnString();

  Timer? _searchTimer;
  int _serial = 0;
  int _summarySerial = 0;

  bool get canWrite => session.can('documents:write');
  bool get canExport => session.can('documents:export');

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() =>
      Future.wait([load(), loadSummary(), loadTypes(), loadDirectories()]);

  Future<void> _refreshData() => Future.wait([load(), loadSummary()]);

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.list(
      filters: filters.value,
      page: page.value,
      limit: limit.value,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        documents.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        documents.clear();
        total.value = 0;
        totalPages.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadSummary() async {
    final serial = ++_summarySerial;
    final result = await repository.summary(filters.value);
    if (serial != _summarySerial) return;
    summary.value = result.when(success: (data) => data, failure: (_) => null);
  }

  /// Active types only: category names, filter options and form choices.
  Future<void> loadTypes() async {
    final result = await repository.types();
    result.when(success: types.assignAll, failure: (_) {});
  }

  /// Each directory is only read with its permission, like the web hooks.
  Future<void> loadDirectories() async {
    const gates = {
      'client': 'clients:read',
      'staff': 'staff:read',
      'residence': 'residences:read',
    };
    await Future.wait([
      for (final MapEntry(key: type, value: permission) in gates.entries)
        if (session.can(permission))
          repository.owners(type).then(
                (result) => result.when(
                  success: (owners) => directories[type] = owners,
                  failure: (_) {},
                ),
              ),
    ]);
  }

  Map<String, String> get typeNames => {for (final t in types) t.id: t.name};

  List<HrDocumentOwner> directoryFor(String ownerType) =>
      directories[ownerType] ?? const [];

  List<HrDocumentRow> get rows {
    final dirs = {
      for (final MapEntry(key: type, value: owners) in directories.entries)
        type: {for (final o in owners) o.id: o.name},
    };
    final names = typeNames;
    final now = _now();
    return [
      for (final d in documents)
        HrDocumentRow.from(d, directories: dirs, typeNames: names, now: now),
    ];
  }

  /// Types a document owned by [ownerType] may be filed as.
  List<HrDocumentType> categoryOptionsFor(String ownerType) => [
        for (final t in types)
          if (t.appliesTo == null || t.appliesTo == 'general' || t.appliesTo == ownerType) t,
      ];

  /// The owner phrase of the form and its success view.
  String ownerLabelOf(HrDocumentDraft draft) {
    if (draft.isTenant) return 'the organisation';
    for (final o in directoryFor(draft.ownerType)) {
      if (o.id == draft.ownerId) return o.name;
    }
    return '';
  }

  String categoryLabelOf(HrDocumentDraft draft) {
    for (final t in categoryOptionsFor(draft.ownerType)) {
      if (t.id == draft.documentTypeId) return t.name;
    }
    return '';
  }

  void _applyFilters(HrDocumentFilters next) {
    filters.value = next;
    page.value = 1;
    _refreshData();
  }

  HrDocumentFilters _with({
    String? search,
    String? ownerType,
    String? documentTypeId,
    String? status,
    String? visibility,
    bool? includeDeleted,
  }) {
    final f = filters.value;
    return HrDocumentFilters(
      search: search ?? f.search,
      ownerType: ownerType ?? f.ownerType,
      documentTypeId: documentTypeId ?? f.documentTypeId,
      status: status ?? f.status,
      visibility: visibility ?? f.visibility,
      includeDeleted: includeDeleted ?? f.includeDeleted,
    );
  }

  void setSearch(String value) {
    searchInput.value = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () {
      final trimmed = value.trim();
      if (trimmed != filters.value.search) _applyFilters(_with(search: trimmed));
    });
  }

  void setOwnerType(String value) => _applyFilters(_with(ownerType: value));
  void setDocumentType(String value) => _applyFilters(_with(documentTypeId: value));
  void setStatus(String value) => _applyFilters(_with(status: value));
  void setVisibility(String value) => _applyFilters(_with(visibility: value));

  void toggleWithdrawn() =>
      _applyFilters(_with(includeDeleted: !filters.value.includeDeleted));

  void applyAlert(HrComplianceAlert alert) {
    final f = alert.filter;
    if (f == null) return;
    _applyFilters(_with(status: f.status, visibility: f.visibility));
  }

  void clearFilters() {
    _searchTimer?.cancel();
    searchInput.value = '';
    _applyFilters(const HrDocumentFilters());
  }

  bool get hasFilters {
    final f = filters.value;
    return f.search.isNotEmpty ||
        f.ownerType.isNotEmpty ||
        f.documentTypeId.isNotEmpty ||
        f.status.isNotEmpty ||
        f.visibility.isNotEmpty ||
        f.includeDeleted;
  }

  void setPage(int value) {
    page.value = value;
    load();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    load();
  }

  Future<void> _run(String id, Future<Result<void>> Function() action, String success) async {
    busyId.value = id;
    final result = await action();
    busyId.value = null;
    result.when(
      success: (_) {
        AppSnackbar.show(success, '');
        _refreshData();
      },
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  Future<void> withdraw(HrDocumentRow row) =>
      _run(row.id, () => repository.withdraw(row.id), 'Document withdrawn');

  Future<void> restore(HrDocumentRow row) =>
      _run(row.id, () => repository.restore(row.id), 'Document restored');

  /// Uploads the file then files the document, or patches an existing one.
  Future<Result<HrDocument>> save(HrDocumentDraft draft, {String? documentId}) async {
    final Result<HrDocument> result;
    if (documentId != null) {
      result = await repository.update(documentId, draft.updateBody());
    } else {
      final upload = await repository.uploadFile(draft.file!);
      if (upload.isFailure) return Result.failure(upload.error!);
      result = await repository.create(draft.createBody(upload.value!));
    }
    if (result.isSuccess) {
      AppSnackbar.show(documentId != null ? 'Document updated' : 'Document filed', '');
      _refreshData();
    }
    return result;
  }

  Future<void> exportReport() async {
    final result = await repository.exportReport();
    result.when(
      success: (_) => AppSnackbar.show(
        'Export queued — it appears under Reports & Exports when ready',
        '',
      ),
      failure: (error) => AppSnackbar.show(error.message, ''),
    );
  }

  Future<void> download(String fileUrl, String name) async {
    final result = await repository.download(fileUrl, name);
    await result.when(
      success: openFile,
      failure: (error) async => AppSnackbar.show(error.message, ''),
    );
  }

  /// Called after a type is added, archived or restored.
  Future<void> typesChanged() => Future.wait([loadTypes(), _refreshData()]);
}
