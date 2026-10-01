import 'dart:math' as math;
import 'dart:typed_data';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../domain/entities/client_extras.dart';
import '../../domain/entities/client_summary.dart';
import '../../domain/repositories/clients_repository.dart';
import '../client_form.dart';
import '../clients_labels.dart';

/// Saves exported CSV bytes; returns an error message or `null`.
typedef ClientsCsvSaver = Future<String?> Function(String fileName, List<int> bytes);

/// Outcome of "Move resident".
class ClientMoveOutcome {
  final bool moved;
  final bool atCapacity;
  final String? message;

  const ClientMoveOutcome({this.moved = false, this.atCapacity = false, this.message});
}

/// Web `/dashboard/clients` ("Client Directory"): search, residence filter,
/// paged list, Add Client wizard, Export List, and the View / Edit / Move /
/// Delete row actions.
class ClientsController extends GetxController {
  final ClientsRepository repository;
  final UserSession? _session;
  final ClientsCsvSaver _saveCsv;

  ClientsController({
    required this.repository,
    UserSession? session,
    ClientsCsvSaver? saveCsv,
  })  : _session = session,
        _saveCsv = saveCsv ?? _saveToDevice;

  final RxList<ClientSummary> clients = <ClientSummary>[].obs;
  final RxInt total = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxInt page = 1.obs;
  final RxInt limit = ClientsLabels.pageSizes.first.obs;
  final RxString query = ''.obs;
  final RxBool isLoading = true.obs;
  final RxnString loadError = RxnString();

  /// `null` means "All Residences".
  final RxnString residenceFilter = RxnString();

  final RxMap<String, String> residenceNames = <String, String>{}.obs;
  final RxnInt clientLimit = RxnInt();
  final RxBool isExporting = false.obs;

  final Map<String, List<ClientRoom>> _rooms = {};
  Worker? _searchWorker;
  int _loadGeneration = 0;

  bool can(String permission) => _session?.can(permission) ?? true;

  bool get canCreate => can('clients:create') || can('clients:write');
  bool get canUpdate => can('clients:update') || can('clients:write');
  bool get canDelete => can('clients:delete');
  bool get canExport => can('clients:export');
  bool get canSeeSpend => can('inventory:read') && can('clients:read');

  /// Count the plan limit is compared against (web `max(meta.total, rows)`).
  int get limitCount => math.max(total.value, clients.length);

  bool get isLimitReached {
    final cap = clientLimit.value;
    return cap != null && limitCount >= cap;
  }

  bool get hasFilters =>
      query.value.trim().isNotEmpty || residenceFilter.value != null;

  /// Residence ids for the filter and pickers, sorted by name.
  List<String> get residenceOptions {
    final ids = residenceNames.keys.toList()
      ..sort((a, b) => residenceLabel(a).compareTo(residenceLabel(b)));
    return ids;
  }

  String residenceLabel(String id) {
    final known = residenceNames[id];
    if (known != null) return known;
    for (final c in clients) {
      if (c.residenceId == id && c.residenceName != null) return c.residenceName!;
    }
    return 'Unknown residence';
  }

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce<String>(
      query,
      (_) {
        page.value = 1;
        loadClients();
      },
      time: const Duration(milliseconds: 300),
    );
    loadClients();
    _loadResidenceNames();
    _loadClientLimit();
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  /// Opens the directory pre-filtered to [residenceId] (or unfiltered).
  void openWith({String? residenceId}) {
    if (residenceFilter.value == residenceId) return;
    residenceFilter.value = residenceId;
    page.value = 1;
    loadClients();
  }

  Future<void> loadClients() async {
    final generation = ++_loadGeneration;
    isLoading.value = true;
    final result = await repository.getClients(
      page: page.value,
      limit: limit.value,
      search: query.value,
      residenceId: residenceFilter.value,
    );
    if (generation != _loadGeneration) return;
    result.when(
      success: (data) {
        clients.assignAll(data.items);
        total.value = data.total;
        totalPages.value = data.totalPages;
        loadError.value = null;
      },
      failure: (error) {
        clients.clear();
        total.value = 0;
        totalPages.value = 0;
        loadError.value = error.message;
      },
    );
    isLoading.value = false;
  }

  @override
  Future<void> refresh() => loadClients();

  void setSearch(String value) => query.value = value;

  void setResidence(String? id) {
    residenceFilter.value = id;
    page.value = 1;
    loadClients();
  }

  void clearFilters() {
    query.value = '';
    residenceFilter.value = null;
    page.value = 1;
    loadClients();
  }

  void setPage(int value) {
    page.value = value;
    loadClients();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    loadClients();
  }

  Future<void> _loadResidenceNames() async {
    final result = await repository.getResidenceNames();
    result.when(success: residenceNames.assignAll, failure: (_) {});
  }

  Future<void> _loadClientLimit() async {
    final result = await repository.getClientLimit();
    result.when(success: (v) => clientLimit.value = v, failure: (_) {});
  }

  Future<ClientSummary?> loadClient(String id) async {
    final result = await repository.getClient(id);
    return result.when(success: (client) => client, failure: (_) => null);
  }

  Future<List<ClientRoom>> roomsFor(String residenceId) async {
    final cached = _rooms[residenceId];
    if (cached != null) return cached;
    final result = await repository.getRooms(residenceId);
    final rooms = result.when(success: (r) => r, failure: (_) => <ClientRoom>[]);
    if (result.isSuccess) _rooms[residenceId] = rooms;
    return rooms;
  }

  Future<Result<List<ClientFamilyMember>>> loadFamily(String clientId) =>
      repository.getFamily(clientId);

  Future<Result<ClientSpend>> loadSpend(String clientId) =>
      repository.getSpend(clientId);

  Future<String?> _uploadPhoto(ClientForm form) async {
    final photo = form.photo;
    if (photo == null) return null;
    final result = await repository.uploadFile(photo, 'client-photos');
    return result.when(
      success: (url) => url,
      failure: (error) => throw error,
    );
  }

  /// Web `g()`: uploads the care plan document and files it on the client.
  Future<void> _fileCarePlan(String clientId, ClientForm form) async {
    final doc = form.carePlanDocument;
    if (doc == null) return;
    final upload = await repository.uploadFile(doc, 'care-plans');
    String? failure;
    final url = upload.when(
      success: (u) => u,
      failure: (e) {
        failure = e.message;
        return null;
      },
    );
    if (url != null) {
      final filed = await repository.fileCarePlanDocument(
        clientId: clientId,
        name: 'Care plan — ${doc.name}',
        fileUrl: url,
      );
      filed.when(success: (_) {}, failure: (e) => failure = e.message);
    }
    if (failure == null) {
      AppSnackbar.show('1 care plan document filed', '', force: true);
    } else {
      AppSnackbar.show('${doc.name} was not filed: $failure', '', force: true);
    }
  }

  /// "Create Client" / "Save Draft". Returns an error message, or `null`.
  Future<String?> createClient(ClientForm form) async {
    try {
      final photoUrl = await _uploadPhoto(form);
      final created = await repository.createClient(
        form.toCreateBody(uploadedPhotoUrl: photoUrl),
      );
      final client = created.when(success: (c) => c, failure: (e) => throw e);
      final guardian = form.guardianBody();
      if (guardian != null) {
        final added = await repository.addFamilyMember(client.id, guardian);
        added.when(success: (_) {}, failure: (e) => throw e);
      }
      AppSnackbar.show('Client added', '', force: true);
      await _fileCarePlan(client.id, form);
      await loadClients();
      return null;
    } on AppError catch (error) {
      final message = error.message.isEmpty ? 'Failed to admit client' : error.message;
      AppSnackbar.show(message, '', force: true);
      return message;
    }
  }

  /// "Save & Close" on the record editor. Returns an error message, or `null`.
  Future<String?> updateClient(ClientSummary client, ClientForm form) async {
    try {
      final photoUrl = await _uploadPhoto(form);
      final updated = await repository.updateClient(
        client.id,
        form.toUpdateBody(uploadedPhotoUrl: photoUrl),
      );
      final saved = updated.when(success: (c) => c, failure: (e) => throw e);
      _replace(saved);
      AppSnackbar.show('Client updated', '', force: true);
      await _fileCarePlan(client.id, form);
      return null;
    } on AppError catch (error) {
      return error.message;
    }
  }

  Future<void> deleteClient(ClientSummary client) async {
    final result = await repository.deleteClient(client.id);
    await result.when(
      success: (_) async {
        AppSnackbar.show('Client deleted', '', force: true);
        await loadClients();
      },
      failure: (error) async => AppSnackbar.show(error.message, '', force: true),
    );
  }

  Future<ClientMoveOutcome> moveClient(
    ClientSummary client,
    ClientTransferRequest request,
  ) async {
    final result = await repository.transferClient(client.id, request);
    return result.when(
      success: (moved) {
        _replace(moved);
        AppSnackbar.show('Resident moved', '', force: true);
        loadClients();
        return const ClientMoveOutcome(moved: true);
      },
      failure: (error) => ClientMoveOutcome(
        atCapacity: _isAtCapacity(error),
        message: error.message,
      ),
    );
  }

  static bool _isAtCapacity(AppError error) {
    if (error.code == 'RESIDENCE_AT_CAPACITY') return true;
    if (error is ApiError && error.statusCode == 409) return true;
    return error.message.toLowerCase().contains('capacity');
  }

  void _replace(ClientSummary updated) {
    final index = clients.indexWhere((c) => c.id == updated.id);
    if (index != -1) clients[index] = updated;
  }

  /// Family contact add / edit / remove. Returns an error message, or `null`.
  Future<String?> saveFamilyMember(
    String clientId,
    Map<String, dynamic> body, {
    String? memberId,
  }) async {
    final result = memberId == null
        ? await repository.addFamilyMember(clientId, body)
        : await repository.updateFamilyMember(clientId, memberId, body);
    return result.when(
      success: (_) {
        AppSnackbar.show(memberId == null ? 'Contact added' : 'Contact updated', '',
            force: true);
        return null;
      },
      failure: (error) {
        AppSnackbar.show(error.message, '', force: true);
        return error.message;
      },
    );
  }

  Future<bool> removeFamilyMember(String clientId, String memberId) async {
    final result = await repository.removeFamilyMember(clientId, memberId);
    return result.when(
      success: (_) {
        AppSnackbar.show('Contact removed', '', force: true);
        return true;
      },
      failure: (error) {
        AppSnackbar.show(error.message, '', force: true);
        return false;
      },
    );
  }

  /// Web "Export List" (`client_roster`).
  Future<void> exportList() async {
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final result = await repository.exportRosterCsv();
      await result.when(
        success: (bytes) async {
          final stamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .split('.')
              .first;
          final error = await _saveCsv('client_roster-$stamp.csv', bytes);
          AppSnackbar.show(error ?? 'Export ready', '', force: true);
        },
        failure: (error) async => AppSnackbar.show(error.message, '', force: true),
      );
    } finally {
      isExporting.value = false;
    }
  }

  static Future<String?> _saveToDevice(String fileName, List<int> bytes) async {
    final saved = await MediaStoreDownload.saveFileAndOpen(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      chooserTitle: 'Open CSV',
    );
    return saved.success ? null : (saved.error ?? 'Could not save or open the CSV file.');
  }
}
