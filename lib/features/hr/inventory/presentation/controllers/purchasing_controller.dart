import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchasing.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_action.dart';

enum PurchasingTab { orders, suppliers }

/// Web `/dashboard/purchasing`: purchase orders and suppliers.
class PurchasingController extends GetxController {
  final InventoryRepository repository;
  final UserSession session;

  PurchasingController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 20, 25, 50];
  static const int _optionsLimit = 100;
  static const int pickerLimit = 20;

  final Rx<PurchasingTab> tab = PurchasingTab.orders.obs;
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;

  final RxList<PurchaseOrder> orders = <PurchaseOrder>[].obs;
  final RxInt ordersTotal = 0.obs;
  final RxBool ordersLoading = true.obs;
  final RxnString ordersError = RxnString();

  final RxList<InventorySupplier> suppliers = <InventorySupplier>[].obs;
  final RxInt suppliersTotal = 0.obs;
  final RxBool suppliersLoading = true.obs;
  final RxnString suppliersError = RxnString();

  /// Every supplier, for the order form's picker.
  final RxList<InventorySupplier> supplierCatalogue = <InventorySupplier>[].obs;
  final RxList<InventoryOption> residences = <InventoryOption>[].obs;
  final RxnString busyId = RxnString();

  int _ordersSerial = 0;
  int _suppliersSerial = 0;

  bool get canWriteOrders => session.can('purchase-orders:write');
  bool get canApprove => session.can('purchase-orders:approve');
  bool get canReceive => session.can('purchase-orders:receive');
  bool get canWriteSuppliers => session.can('suppliers:write');
  bool get canReadOrders => session.can('purchase-orders:read');
  bool get canReadSuppliers => session.can('suppliers:read');

  int get total => tab.value == PurchasingTab.orders ? ordersTotal.value : suppliersTotal.value;

  int get totalPages => total == 0 ? 1 : ((total + limit.value - 1) ~/ limit.value);

  /// Web `useSupplierOptions(residenceId)`.
  List<InventoryOption> supplierOptionsFor(String? residence) => [
        for (final s in supplierCatalogue)
          if (!s.isDeleted &&
              (residence == null ||
                  residence.isEmpty ||
                  s.residenceId == null ||
                  s.residenceId == residence))
            InventoryOption(
              value: s.id,
              label: s.residenceId != null ? s.name : '${s.name} (all residences)',
            ),
      ];

  @override
  void onInit() {
    super.onInit();
    refreshAll();
    loadOptions();
  }

  Future<void> refreshAll() => Future.wait([loadOrders(), loadSuppliers()]);

  Future<void> loadOrders() async {
    if (!canReadOrders) {
      ordersLoading.value = false;
      return;
    }
    final serial = ++_ordersSerial;
    ordersLoading.value = true;
    final result = await repository.purchaseOrders(page: page.value, limit: limit.value);
    if (serial != _ordersSerial) return;
    result.when(
      success: (data) {
        orders.assignAll(data.items);
        ordersTotal.value = data.total;
        ordersError.value = null;
      },
      failure: (error) {
        orders.clear();
        ordersTotal.value = 0;
        ordersError.value = error.message;
      },
    );
    ordersLoading.value = false;
  }

  Future<void> loadSuppliers() async {
    if (!canReadSuppliers) {
      suppliersLoading.value = false;
      return;
    }
    final serial = ++_suppliersSerial;
    suppliersLoading.value = true;
    final result = await repository.suppliers(page: page.value, limit: limit.value);
    if (serial != _suppliersSerial) return;
    result.when(
      success: (data) {
        suppliers.assignAll(data.items);
        suppliersTotal.value = data.total;
        suppliersError.value = null;
      },
      failure: (error) {
        suppliers.clear();
        suppliersTotal.value = 0;
        suppliersError.value = error.message;
      },
    );
    suppliersLoading.value = false;
  }

  Future<void> loadOptions() async {
    if (session.can('residences:read')) {
      (await repository.residences()).when(success: residences.assignAll, failure: (_) {});
    }
    if (canReadSuppliers) {
      (await repository.suppliers(page: 1, limit: _optionsLimit))
          .when(success: (data) => supplierCatalogue.assignAll(data.items), failure: (_) {});
    }
  }

  void setTab(PurchasingTab value) {
    tab.value = value;
    page.value = 1;
    refreshAll();
  }

  void setPage(int value) {
    page.value = value;
    refreshAll();
  }

  void setLimit(int value) {
    limit.value = value;
    page.value = 1;
    refreshAll();
  }

  /// Items on [residenceId]'s shelves matching [search], for the line picker.
  Future<Result<List<InventoryItem>>> searchStock(String residenceId, String search) async {
    final result = await repository.items(
      page: 1,
      limit: pickerLimit,
      residenceId: residenceId,
      search: search.trim().isEmpty ? null : search.trim(),
    );
    return result.when(
      success: (data) => Result.success(data.items),
      failure: Result.failure,
    );
  }

  Future<void> _afterChange() async {
    await refreshAll();
    await loadOptions();
  }

  Future<String?> _row(PurchaseOrder order, Future<Result<void>> Function() action, String success) async {
    busyId.value = order.id;
    final error = await runInventoryAction(action, success: success, onSuccess: _afterChange);
    busyId.value = null;
    return error;
  }

  Future<String?> submit(PurchaseOrder order) =>
      _row(order, () => repository.submitOrder(order.id), 'Order submitted');

  Future<String?> requestApproval(PurchaseOrder order) =>
      _row(order, () => repository.requestOrderApproval(order.id), 'Sent for approval');

  Future<String?> approve(PurchaseOrder order) =>
      _row(order, () => repository.approveOrder(order.id), 'Order approved');

  Future<String?> cancel(PurchaseOrder order) =>
      _row(order, () => repository.cancelOrder(order.id), 'Order cancelled');

  Future<String?> reject(PurchaseOrder order, String reason) => runInventoryAction(
        () => repository.rejectOrder(order.id, reason),
        success: 'Order rejected',
        toastErrors: false,
        onSuccess: _afterChange,
      );

  Future<String?> createOrder(Map<String, dynamic> body) => runInventoryAction(
        () => repository.createOrder(body),
        success: 'Draft order created',
        toastErrors: false,
        onSuccess: _afterChange,
      );

  Future<String?> updateOrder(String id, Map<String, dynamic> body) => runInventoryAction(
        () => repository.updateOrder(id, body),
        success: 'Order updated',
        toastErrors: false,
        onSuccess: _afterChange,
      );

  Future<String?> receive(String id, Map<String, dynamic> body) => runInventoryAction(
        () => repository.receiveOrder(id, body),
        success: 'Booked in — stock updated',
        toastErrors: false,
        onSuccess: _afterChange,
      );

  Future<String?> addSupplier(String name, String category) => runInventoryAction(
        () => repository.createSupplier(name: name, category: category),
        success: 'Supplier added',
        toastErrors: false,
        onSuccess: _afterChange,
      );

  Future<String?> removeSupplier(InventorySupplier supplier) => runInventoryAction(
        () => repository.removeSupplier(supplier.id),
        onSuccess: _afterChange,
      );

  Future<String?> restoreSupplier(InventorySupplier supplier) => runInventoryAction(
        () => repository.restoreSupplier(supplier.id),
        onSuccess: _afterChange,
      );
}
