import 'package:get/get.dart';
import 'package:gems_core/gems_core.dart';

import '../../domain/entities/staff_document.dart';
import '../../domain/repositories/staff_documents_repository.dart';

class StaffDocumentsController extends GetxController {
  final StaffDocumentsRepository repository;

  StaffDocumentsController({required this.repository});

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final summary = const StaffDocumentsSummary().obs;
  final documents = <StaffDocument>[].obs;
  final types = <StaffDocumentType>[].obs;

  final searchQuery = ''.obs;
  final ownerTypeFilter = ''.obs;
  final documentTypeFilter = ''.obs;
  final statusFilter = ''.obs;
  final visibilityFilter = ''.obs;
  final includeDeleted = false.obs;

  final page = 1.obs;
  final pageSize = 20.obs;
  final total = 0.obs;
  final totalPages = 1.obs;

  final clients = <StaffDocumentOwnerOption>[].obs;
  final staff = <StaffDocumentOwnerOption>[].obs;
  final residences = <StaffDocumentOwnerOption>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    await Future.wait([
      _loadSummary(),
      _loadTypes(),
      _loadDocuments(),
      _loadOwners(),
    ]);
    isLoading.value = false;
  }

  Future<void> reload() async {
    isRefreshing.value = true;
    errorMessage.value = '';
    await Future.wait([
      _loadSummary(),
      _loadTypes(),
      _loadDocuments(),
    ]);
    isRefreshing.value = false;
  }

  Future<void> _loadSummary() async {
    final result = await repository.getSummary();
    result.when(
      success: (data) => summary.value = data,
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadTypes() async {
    final result = await repository.listTypes(includeArchived: true);
    result.when(
      success: (data) => types.assignAll(data),
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadDocuments() async {
    final result = await repository.listDocuments(
      page: page.value,
      limit: pageSize.value,
      search: searchQuery.value,
      ownerType: ownerTypeFilter.value,
      documentTypeId: documentTypeFilter.value,
      status: statusFilter.value,
      visibility: visibilityFilter.value,
      includeDeleted: includeDeleted.value,
    );
    result.when(
      success: (data) {
        documents.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages < 1 ? 1 : data.totalPages;
        page.value = data.page;
      },
      failure: (error) => errorMessage.value = error.message,
    );
  }

  Future<void> _loadOwners() async {
    final results = await Future.wait([
      repository.listClients(),
      repository.listStaff(),
      repository.listResidences(),
    ]);
    results[0].when(
      success: (data) => clients.assignAll(data),
      failure: (_) {},
    );
    results[1].when(
      success: (data) => staff.assignAll(data),
      failure: (_) {},
    );
    results[2].when(
      success: (data) => residences.assignAll(data),
      failure: (_) {},
    );
  }

  void setSearch(String value) {
    searchQuery.value = value;
    page.value = 1;
    _loadDocuments();
  }

  void setFilter({
    String? ownerType,
    String? documentTypeId,
    String? status,
    String? visibility,
  }) {
    if (ownerType != null) ownerTypeFilter.value = ownerType;
    if (documentTypeId != null) documentTypeFilter.value = documentTypeId;
    if (status != null) statusFilter.value = status;
    if (visibility != null) visibilityFilter.value = visibility;
    page.value = 1;
    _loadDocuments();
  }

  void clearFilters() {
    searchQuery.value = '';
    ownerTypeFilter.value = '';
    documentTypeFilter.value = '';
    statusFilter.value = '';
    visibilityFilter.value = '';
    page.value = 1;
    _loadDocuments();
  }

  void toggleWithdrawn() {
    includeDeleted.value = !includeDeleted.value;
    page.value = 1;
    _loadDocuments();
  }

  void goToPage(int next) {
    if (next < 1 || next > totalPages.value) return;
    page.value = next;
    _loadDocuments();
  }

  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      ownerTypeFilter.value.isNotEmpty ||
      documentTypeFilter.value.isNotEmpty ||
      statusFilter.value.isNotEmpty ||
      visibilityFilter.value.isNotEmpty;

  List<StaffDocumentType> get activeTypes =>
      types.where((t) => t.isActive).toList();

  Future<Result<void>> createType({
    required String name,
    required String appliesTo,
  }) async {
    final result = await repository.createType(name: name, appliesTo: appliesTo);
    return result.when(
      success: (_) async {
        await _loadTypes();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> archiveType(String id) async {
    final result = await repository.archiveType(id);
    return result.when(
      success: (_) async {
        await _loadTypes();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> restoreType(String id) async {
    final result = await repository.restoreType(id);
    return result.when(
      success: (_) async {
        await _loadTypes();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> uploadDocument({
    required String name,
    required String ownerType,
    String? ownerId,
    String? documentTypeId,
    required String localPath,
    required String fileName,
    required String visibility,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final upload = await repository.uploadFile(
      localPath: localPath,
      fileName: fileName,
    );
    if (upload.isFailure) return Result.failure(upload.error!);

    final create = await repository.createDocument(
      StaffCreateDocumentInput(
        name: name,
        ownerType: ownerType,
        ownerId: ownerId,
        documentTypeId: documentTypeId,
        fileUrl: upload.value!,
        visibility: visibility,
        expiresAt: expiresAt,
        notes: notes,
      ),
    );
    return create.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> withdraw(String id) async {
    final result = await repository.withdrawDocument(id);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> restore(String id) async {
    final result = await repository.restoreDocument(id);
    return result.when(
      success: (_) async {
        await reload();
        return Result.success(null);
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
