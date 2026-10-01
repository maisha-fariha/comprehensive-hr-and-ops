import 'package:gems_core/gems_core.dart';
import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/stock_ops.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_action.dart';

/// Web `/dashboard/inventory/transfers` ("Stock transfers").
class StockTransfersController extends GetxController {
  final InventoryRepository repository;
  final UserSession session;

  StockTransfersController({required this.repository, required this.session});

  static const List<int> pageSizes = [10, 25, 50];
  static const int sendingShelfLimit = 200;

  final RxList<StockTransfer> transfers = <StockTransfer>[].obs;
  final RxInt total = 0.obs;
  final RxBool loading = true.obs;
  final RxnString loadError = RxnString();
  final RxInt page = 1.obs;
  final RxInt limit = 20.obs;
  final RxnString busyId = RxnString();
  final RxList<InventoryOption> residences = <InventoryOption>[].obs;

  int _serial = 0;

  bool get canRequest => session.can('inventory:transfer:request');
  bool get canApprove => session.can('inventory:transfer:approve');
  bool get canDispatch => session.can('inventory:transfer:dispatch');
  bool get canReceive => session.can('inventory:transfer:receive');

  /// The web lets requesters and approvers cancel.
  bool get canCancel => canRequest || canApprove;

  bool canStep(String step) => switch (step) {
        'approve' => canApprove,
        'dispatch' => canDispatch,
        'receive' => canReceive,
        _ => false,
      };

  int get totalPages =>
      total.value == 0 ? 1 : ((total.value + limit.value - 1) ~/ limit.value);

  @override
  void onInit() {
    super.onInit();
    load();
    loadResidences();
  }

  Future<void> load() async {
    final serial = ++_serial;
    loading.value = true;
    final result = await repository.transfers(page: page.value, limit: limit.value);
    if (serial != _serial) return;
    result.when(
      success: (data) {
        transfers.assignAll(data.items);
        total.value = data.total;
        loadError.value = null;
      },
      failure: (error) {
        transfers.clear();
        total.value = 0;
        loadError.value = error.message;
      },
    );
    loading.value = false;
  }

  Future<void> loadResidences() async {
    if (!session.can('residences:read')) return;
    (await repository.residences()).when(success: residences.assignAll, failure: (_) {});
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

  /// Every item on the sending house's shelves.
  Future<Result<List<InventoryItem>>> shelf(String residenceId) async {
    final result = await repository.items(
      page: 1,
      limit: sendingShelfLimit,
      residenceId: residenceId,
    );
    return result.when(
      success: (data) => Result.success(data.items),
      failure: Result.failure,
    );
  }

  Future<Result<List<InventoryBatch>>> lots(String itemId) => repository.batches(itemId);

  Future<String?> create(Map<String, dynamic> body) => runInventoryAction(
        () => repository.createTransfer(body),
        success: 'Transfer requested',
        toastErrors: false,
        onSuccess: load,
      );

  Future<String?> _busy(StockTransfer transfer, Future<String?> Function() run) async {
    busyId.value = transfer.id;
    final error = await run();
    busyId.value = null;
    return error;
  }

  Future<String?> approve(StockTransfer transfer) => _busy(
        transfer,
        () => runInventoryAction(
          () => repository.approveTransfer(transfer.id),
          success: 'Transfer approved',
          onSuccess: load,
        ),
      );

  Future<String?> cancel(StockTransfer transfer) => _busy(
        transfer,
        () => runInventoryAction(
          () => repository.cancelTransfer(transfer.id),
          success: 'Transfer cancelled',
          onSuccess: load,
        ),
      );

  Future<String?> dispatch(String transferId, List<Map<String, dynamic>> lines) =>
      runInventoryAction(
        () => repository.dispatchTransfer(transferId, lines),
        success: 'On its way — stock has left the sending house',
        toastErrors: false,
        onSuccess: load,
      );

  Future<String?> receive(String transferId, List<Map<String, dynamic>> lines) {
    final shortfalls = lines.where((l) => l['shortfallReason'] != null).length;
    return runInventoryAction(
      () => repository.receiveTransfer(transferId, lines),
      success: shortfalls > 0
          ? 'Booked in — $shortfalls shortfall${shortfalls == 1 ? '' : 's'} logged against '
              'the sending house'
          : 'Booked in — stock is now at the receiving house',
      toastErrors: false,
      onSuccess: load,
    );
  }
}
