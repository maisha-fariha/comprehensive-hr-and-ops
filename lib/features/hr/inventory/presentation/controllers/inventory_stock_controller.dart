import 'dart:async';

import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchasing.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_action.dart';

/// Web `/dashboard/inventory` ("Stock"): filters, KPI tiles, the
/// needs-ordering / expiring panels, the paged item list, the movement log
/// and recent losses.
class InventoryStockController extends GetxController {
  final InventoryRepository repository;
  final UserSession session;

  InventoryStockController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 20, 25, 50];
  static const int defaultLimit = 20;
  static const int needsOrderingLimit = 5;
  static const int expiringWithinDays = 30;
  static const int recentMovementLimit = 8;
  static const int recentLossLimit = 20;
  static const int _optionsLimit = 100;

  final RxList<InventoryItem> items = <InventoryItem>[].obs;
  final RxInt total = 0.obs;
  final Rx<InventorySummary> summary = const InventorySummary().obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();

  final RxInt page = 1.obs;
  final RxInt limit = defaultLimit.obs;
  final RxString search = ''.obs;
  final RxnString residenceId = RxnString();
  final RxnString categoryId = RxnString();
  final RxBool lowStock = false.obs;

  final RxList<InventoryOption> residences = <InventoryOption>[].obs;
  final RxList<InventoryCatalogueEntry> categories = <InventoryCatalogueEntry>[].obs;
  final RxList<InventoryCatalogueEntry> unitTypes = <InventoryCatalogueEntry>[].obs;
  final RxBool categoriesLoading = true.obs;
  final RxList<InventorySupplier> suppliers = <InventorySupplier>[].obs;

  final RxList<InventoryItem> lowItems = <InventoryItem>[].obs;
  final RxInt lowTotal = 0.obs;
  final RxBool lowLoading = true.obs;
  final RxList<InventoryBatch> expiring = <InventoryBatch>[].obs;
  final RxBool expiringLoading = true.obs;
  final RxList<StockMovement> movements = <StockMovement>[].obs;
  final RxBool movementsLoading = true.obs;
  final RxBool movementsFailed = false.obs;
  final RxList<InventoryLoss> losses = <InventoryLoss>[].obs;

  int _serial = 0;
  Timer? _searchDebounce;

  bool get canWrite => session.can('inventory:write');
  bool get canMove => session.can('inventory:movement');
  bool get canAdjust => session.can('inventory:adjustment');
  bool get canWaste => session.can('inventory:waste');
  bool get canWriteSuppliers => session.can('suppliers:write');
  bool get canReadSuppliers => session.can('suppliers:read');
  bool get canReadResidences => session.can('residences:read');

  int get totalPages =>
      total.value == 0 ? 1 : ((total.value + limit.value - 1) ~/ limit.value);

  List<InventoryOption> get categoryOptions => [
        for (final c in categories)
          if (c.isActive) InventoryOption(value: c.id, label: c.name),
      ];

  /// Web `useUnitTypeOptions`: the code is stored on the item.
  List<InventoryOption> get unitOptions => [
        for (final u in unitTypes)
          if (u.isActive && u.code != null)
            InventoryOption(value: u.code!, label: '${u.name} (${u.code})'),
      ];

  /// Web `useSupplierOptions(residenceId)`.
  List<InventoryOption> supplierOptionsFor(String? residence) => [
        for (final s in suppliers)
          if (!s.isDeleted &&
              (residence == null || s.residenceId == null || s.residenceId == residence))
            InventoryOption(
              value: s.id,
              label: s.residenceId != null ? s.name : '${s.name} (all residences)',
            ),
      ];

  /// Supplier names offered by the item form for [residence].
  List<String> supplierNamesFor(String? residence, {String? current}) {
    final names = [
      for (final s in suppliers)
        if (!s.isDeleted && s.isActive && (s.residenceId == null || s.residenceId == residence))
          s.name,
    ];
    if (current != null && current.isNotEmpty && !names.contains(current)) {
      names.insert(0, current);
    }
    return names.toSet().toList();
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
    loadCatalogues();
    loadOptions();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() =>
      Future.wait([load(), loadPanels(), loadMovements(), loadLosses()]);

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.items(
      page: page.value,
      limit: limit.value,
      search: search.value.trim().isEmpty ? null : search.value.trim(),
      residenceId: residenceId.value,
      categoryId: categoryId.value,
      lowStock: lowStock.value,
    );
    if (serial != _serial) return;
    result.when(
      success: (data) {
        items.assignAll(data.items);
        total.value = data.total;
        summary.value = data.summary;
        loadError.value = null;
      },
      failure: (error) {
        items.clear();
        total.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadPanels() async {
    lowLoading.value = true;
    expiringLoading.value = true;
    final low = repository.items(
      page: 1,
      limit: needsOrderingLimit,
      residenceId: residenceId.value,
      lowStock: true,
    );
    final soon = repository.expiringBatches(
      withinDays: expiringWithinDays,
      residenceId: residenceId.value,
    );
    (await low).when(
      success: (data) {
        lowItems.assignAll(data.items);
        lowTotal.value = data.total;
      },
      failure: (_) {
        lowItems.clear();
        lowTotal.value = 0;
      },
    );
    lowLoading.value = false;
    (await soon).when(
      success: expiring.assignAll,
      failure: (_) => expiring.clear(),
    );
    expiringLoading.value = false;
  }

  Future<void> loadMovements() async {
    movementsLoading.value = true;
    final result = await repository.movements(
      residenceId: residenceId.value,
      limit: recentMovementLimit,
    );
    result.when(
      success: (rows) {
        movements.assignAll(rows);
        movementsFailed.value = false;
      },
      failure: (_) {
        movements.clear();
        movementsFailed.value = true;
      },
    );
    movementsLoading.value = false;
  }

  Future<void> loadLosses() async {
    final result = await repository.losses(page: 1, limit: recentLossLimit);
    result.when(success: losses.assignAll, failure: (_) => losses.clear());
  }

  Future<void> loadCatalogues() async {
    categoriesLoading.value = true;
    final cats = repository.categories(includeArchived: true);
    final units = repository.unitTypes(includeArchived: true);
    (await cats).when(success: categories.assignAll, failure: (_) {});
    categoriesLoading.value = false;
    (await units).when(success: unitTypes.assignAll, failure: (_) {});
  }

  Future<void> loadOptions() async {
    if (canReadResidences) {
      (await repository.residences()).when(success: residences.assignAll, failure: (_) {});
    }
    if (canReadSuppliers) {
      (await repository.suppliers(page: 1, limit: _optionsLimit))
          .when(success: (data) => suppliers.assignAll(data.items), failure: (_) {});
    }
  }

  void setSearch(String value) {
    search.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      page.value = 1;
      load();
    });
  }

  void setResidence(String? value) {
    residenceId.value = value;
    page.value = 1;
    load();
    loadPanels();
    loadMovements();
  }

  void setCategory(String? value) {
    categoryId.value = value;
    page.value = 1;
    load();
  }

  void setLowStock(bool value) {
    lowStock.value = value;
    page.value = 1;
    load();
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

  Future<String?> _run(
    Future<Result<void>> Function() action, {
    String? success,
    bool toastErrors = true,
  }) =>
      runInventoryAction(
        action,
        success: success,
        toastErrors: toastErrors,
        onSuccess: refreshAll,
      );

  Future<String?> createItem(Map<String, dynamic> body) =>
      _run(() => repository.createItem(body), success: 'Item added', toastErrors: false);

  Future<String?> updateItem(String id, Map<String, dynamic> body) =>
      _run(() => repository.updateItem(id, body), success: 'Item updated', toastErrors: false);

  Future<String?> deleteItem(InventoryItem item) =>
      _run(() => repository.deleteItem(item.id), success: 'Item deleted');

  Future<String?> moveStock(InventoryItem item, num changeQty, String? reason) => _run(
        () => repository.move(item.id, {'changeQty': changeQty, 'reason': ?reason}),
        success: changeQty < 0 ? 'Stock taken out' : 'Stock added in',
        toastErrors: false,
      );

  Future<String?> recount(InventoryItem item, num counted, String reason) => _run(
        () => repository.adjust(item.id, {'countedQuantity': counted, 'reason': reason}),
        success: 'Count corrected',
        toastErrors: false,
      );

  Future<String?> recordLoss(
    InventoryItem item, {
    required String type,
    required num quantity,
    String? batchId,
    String? notes,
  }) =>
      _run(
        () => repository.recordLoss({
          'itemId': item.id,
          'exceptionType': type,
          'quantity': quantity,
          'batchId': ?batchId,
          'notes': ?notes,
        }),
        success: 'Loss recorded',
        toastErrors: false,
      );

  Future<String?> addBatch(String itemId, Map<String, dynamic> body) =>
      _run(() => repository.addBatch(itemId, body), success: 'Lot recorded');

  Future<String?> updateBatch(String itemId, String batchId, Map<String, dynamic> body) =>
      _run(() => repository.updateBatch(itemId, batchId, body), success: 'Lot corrected');

  Future<String?> linkSupplier(String itemId, Map<String, dynamic> body) =>
      _run(() => repository.linkSupplier(itemId, body), success: 'Supplier added');

  Future<String?> unlinkSupplier(String itemId, String linkId) =>
      _run(() => repository.unlinkSupplier(itemId, linkId), success: 'Supplier removed');

  Future<String?> _catalogue(Future<Result<void>> Function() action, String success) =>
      runInventoryAction(action, success: success, onSuccess: () async {
        await loadCatalogues();
        await load();
      });

  Future<String?> addCategory(String name) =>
      _catalogue(() => repository.createCategory(name), 'Category added');

  Future<String?> renameCategory(String id, String name) =>
      _catalogue(() => repository.renameCategory(id, name), 'Renamed');

  Future<String?> archiveCategory(InventoryCatalogueEntry entry) => _catalogue(
        () => repository.archiveCategory(entry.id, entry.isActive),
        entry.isActive ? 'Retired' : 'Back in the list',
      );

  Future<String?> addUnitType(String code, String name) =>
      _catalogue(() => repository.createUnitType(code, name), 'Unit added');

  Future<String?> renameUnitType(String id, String name) =>
      _catalogue(() => repository.renameUnitType(id, name), 'Renamed');

  Future<String?> archiveUnitType(InventoryCatalogueEntry entry) => _catalogue(
        () => repository.archiveUnitType(entry.id, entry.isActive),
        entry.isActive ? 'Retired' : 'Back in the list',
      );
}
