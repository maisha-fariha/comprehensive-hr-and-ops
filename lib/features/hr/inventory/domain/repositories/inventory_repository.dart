import 'package:gems_core/gems_core.dart';

import '../entities/inventory_item.dart';
import '../entities/purchasing.dart';
import '../entities/stock_ops.dart';

/// Outcome of "Open count": the new count, or the draft already open for
/// the same shelves.
class StockCountOpened {
  final String id;
  final bool alreadyOpen;

  const StockCountOpened({required this.id, this.alreadyOpen = false});
}

abstract class InventoryRepository {
  // ---- Stock ----

  /// `GET /inventory/items` with `meta.summary`.
  Future<Result<InventoryItemPage>> items({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
    String? categoryId,
    bool lowStock = false,
  });

  Future<Result<void>> createItem(Map<String, dynamic> body);

  Future<Result<void>> updateItem(String id, Map<String, dynamic> body);

  Future<Result<void>> deleteItem(String id);

  /// Recount: `{countedQuantity, reason}`.
  Future<Result<void>> adjust(String id, Map<String, dynamic> body);

  /// Move: `{changeQty, reason?}`.
  Future<Result<void>> move(String id, Map<String, dynamic> body);

  /// Loss: `{itemId, exceptionType, quantity, batchId?, notes?}`.
  Future<Result<void>> recordLoss(Map<String, dynamic> body);

  Future<Result<List<InventoryBatch>>> batches(String itemId);

  Future<Result<void>> addBatch(String itemId, Map<String, dynamic> body);

  Future<Result<void>> updateBatch(
    String itemId,
    String batchId,
    Map<String, dynamic> body,
  );

  Future<Result<List<InventoryBatch>>> expiringBatches({
    required int withinDays,
    String? residenceId,
  });

  /// `/inventory/items/:id/transactions` when [itemId] is set, else
  /// `/inventory/transactions`.
  Future<Result<List<StockMovement>>> movements({
    String? itemId,
    String? residenceId,
    required int limit,
  });

  Future<Result<List<InventoryCostEntry>>> costHistory(String itemId);

  Future<Result<List<InventoryItemSupplier>>> itemSuppliers(String itemId);

  Future<Result<void>> linkSupplier(String itemId, Map<String, dynamic> body);

  Future<Result<void>> unlinkSupplier(String itemId, String linkId);

  Future<Result<List<InventoryLoss>>> losses({required int page, required int limit});

  Future<Result<List<InventoryCatalogueEntry>>> categories({bool includeArchived = false});

  Future<Result<List<InventoryCatalogueEntry>>> unitTypes({bool includeArchived = false});

  Future<Result<void>> createCategory(String name);

  Future<Result<void>> renameCategory(String id, String name);

  Future<Result<void>> archiveCategory(String id, bool archive);

  Future<Result<void>> createUnitType(String code, String name);

  Future<Result<void>> renameUnitType(String id, String name);

  Future<Result<void>> archiveUnitType(String id, bool archive);

  Future<Result<List<InventoryOption>>> residences();

  // ---- Stock counts ----

  Future<Result<InventoryListPage<StockCount>>> stockCounts({
    required int page,
    required int limit,
  });

  Future<Result<StockCount>> stockCount(String id);

  Future<Result<StockCountOpened>> openStockCount({
    required String residenceId,
    String? categoryId,
  });

  /// `{lines: [{lineId, countedQty}]}`.
  Future<Result<void>> saveCountLines(String id, List<Map<String, dynamic>> lines);

  Future<Result<void>> submitCount(String id);

  Future<Result<void>> cancelCount(String id);

  // ---- Transfers ----

  Future<Result<InventoryListPage<StockTransfer>>> transfers({
    required int page,
    required int limit,
  });

  Future<Result<void>> createTransfer(Map<String, dynamic> body);

  Future<Result<void>> approveTransfer(String id);

  /// `{lines: [{lineId, quantity}]}`.
  Future<Result<void>> dispatchTransfer(String id, List<Map<String, dynamic>> lines);

  /// `{lines: [{lineId, receivedQuantity, shortfallReason?, shortfallNotes?}]}`.
  Future<Result<void>> receiveTransfer(String id, List<Map<String, dynamic>> lines);

  Future<Result<void>> cancelTransfer(String id);

  // ---- Purchasing ----

  Future<Result<InventoryListPage<InventorySupplier>>> suppliers({
    required int page,
    required int limit,
  });

  Future<Result<void>> createSupplier({required String name, required String category});

  Future<Result<void>> removeSupplier(String id);

  Future<Result<void>> restoreSupplier(String id);

  Future<Result<InventoryListPage<PurchaseOrder>>> purchaseOrders({
    required int page,
    required int limit,
  });

  Future<Result<void>> createOrder(Map<String, dynamic> body);

  Future<Result<void>> updateOrder(String id, Map<String, dynamic> body);

  Future<Result<void>> submitOrder(String id);

  Future<Result<void>> requestOrderApproval(String id);

  Future<Result<void>> approveOrder(String id);

  Future<Result<void>> rejectOrder(String id, String reason);

  /// `{items: [{itemId, receivedQuantity, batchNo?, expiryDate?}], notes?}`.
  Future<Result<void>> receiveOrder(String id, Map<String, dynamic> body);

  Future<Result<void>> cancelOrder(String id);
}
