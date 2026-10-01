import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchasing.dart';
import '../../domain/entities/stock_ops.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../inventory_endpoints.dart';
import '../mappers/inventory_mapper.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final AppApiClient _api;

  InventoryRepositoryImpl({required AppApiClient api}) : _api = api;

  static const int _optionsLimit = 100;

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  Future<Result<T>> _get<T>(
    String path,
    T Function(dynamic body) map, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _api.get(path, query: query, silent: true);
    return result.when(
      success: (body) => Result.success(map(body)),
      failure: Result.failure,
    );
  }

  Future<Result<void>> _post(String path, [Map<String, dynamic>? data]) async =>
      _done(await _api.post(path, data: data ?? const {}, silent: true, allowQueue: false));

  Future<Result<void>> _patch(String path, Map<String, dynamic> data) async =>
      _done(await _api.patch(path, data: data, silent: true, allowQueue: false));

  Future<Result<void>> _delete(String path) async =>
      _done(await _api.delete(path, silent: true, allowQueue: false));

  // ---- Stock ----

  @override
  Future<Result<InventoryItemPage>> items({
    required int page,
    required int limit,
    String? search,
    String? residenceId,
    String? categoryId,
    bool lowStock = false,
  }) =>
      _get(
        InventoryEndpoints.items,
        InventoryMapper.itemPageFrom,
        query: {
          'page': page,
          'limit': limit,
          'search': ?search,
          'residenceId': ?residenceId,
          'categoryId': ?categoryId,
          if (lowStock) 'lowStock': true,
        },
      );

  @override
  Future<Result<void>> createItem(Map<String, dynamic> body) =>
      _post(InventoryEndpoints.items, body);

  @override
  Future<Result<void>> updateItem(String id, Map<String, dynamic> body) =>
      _patch(InventoryEndpoints.item(id), body);

  @override
  Future<Result<void>> deleteItem(String id) => _delete(InventoryEndpoints.item(id));

  @override
  Future<Result<void>> adjust(String id, Map<String, dynamic> body) =>
      _post(InventoryEndpoints.itemAdjust(id), body);

  @override
  Future<Result<void>> move(String id, Map<String, dynamic> body) =>
      _post(InventoryEndpoints.itemTransactions(id), body);

  @override
  Future<Result<void>> recordLoss(Map<String, dynamic> body) =>
      _post(InventoryEndpoints.exceptions, body);

  @override
  Future<Result<List<InventoryBatch>>> batches(String itemId) =>
      _get(InventoryEndpoints.itemBatches(itemId), InventoryMapper.batchesFrom);

  @override
  Future<Result<void>> addBatch(String itemId, Map<String, dynamic> body) =>
      _post(InventoryEndpoints.itemBatches(itemId), body);

  @override
  Future<Result<void>> updateBatch(
    String itemId,
    String batchId,
    Map<String, dynamic> body,
  ) =>
      _patch(InventoryEndpoints.itemBatch(itemId, batchId), body);

  @override
  Future<Result<List<InventoryBatch>>> expiringBatches({
    required int withinDays,
    String? residenceId,
  }) =>
      _get(
        InventoryEndpoints.expiringBatches,
        InventoryMapper.batchesFrom,
        query: {'withinDays': withinDays, 'residenceId': ?residenceId},
      );

  @override
  Future<Result<List<StockMovement>>> movements({
    String? itemId,
    String? residenceId,
    required int limit,
  }) =>
      _get(
        itemId == null
            ? InventoryEndpoints.transactions
            : InventoryEndpoints.itemTransactions(itemId),
        InventoryMapper.movementsFrom,
        query: {'residenceId': ?residenceId, 'limit': limit},
      );

  @override
  Future<Result<List<InventoryCostEntry>>> costHistory(String itemId) =>
      _get(InventoryEndpoints.itemCostHistory(itemId), InventoryMapper.costHistoryFrom);

  @override
  Future<Result<List<InventoryItemSupplier>>> itemSuppliers(String itemId) =>
      _get(InventoryEndpoints.itemSuppliers(itemId), InventoryMapper.itemSuppliersFrom);

  @override
  Future<Result<void>> linkSupplier(String itemId, Map<String, dynamic> body) =>
      _post(InventoryEndpoints.itemSuppliers(itemId), body);

  @override
  Future<Result<void>> unlinkSupplier(String itemId, String linkId) =>
      _delete(InventoryEndpoints.itemSupplier(itemId, linkId));

  @override
  Future<Result<List<InventoryLoss>>> losses({required int page, required int limit}) =>
      _get(
        InventoryEndpoints.exceptions,
        InventoryMapper.lossesFrom,
        query: {'page': page, 'limit': limit},
      );

  @override
  Future<Result<List<InventoryCatalogueEntry>>> categories({bool includeArchived = false}) =>
      _get(
        InventoryEndpoints.categories,
        InventoryMapper.catalogueFrom,
        query: {'includeArchived': includeArchived},
      );

  @override
  Future<Result<List<InventoryCatalogueEntry>>> unitTypes({bool includeArchived = false}) =>
      _get(
        InventoryEndpoints.unitTypes,
        InventoryMapper.catalogueFrom,
        query: {'includeArchived': includeArchived},
      );

  @override
  Future<Result<void>> createCategory(String name) =>
      _post(InventoryEndpoints.categories, {'name': name});

  @override
  Future<Result<void>> renameCategory(String id, String name) =>
      _patch(InventoryEndpoints.category(id), {'name': name});

  @override
  Future<Result<void>> archiveCategory(String id, bool archive) =>
      _post(InventoryEndpoints.categoryArchive(id, archive));

  @override
  Future<Result<void>> createUnitType(String code, String name) =>
      _post(InventoryEndpoints.unitTypes, {'code': code, 'name': name});

  @override
  Future<Result<void>> renameUnitType(String id, String name) =>
      _patch(InventoryEndpoints.unitType(id), {'name': name});

  @override
  Future<Result<void>> archiveUnitType(String id, bool archive) =>
      _post(InventoryEndpoints.unitTypeArchive(id, archive));

  @override
  Future<Result<List<InventoryOption>>> residences() => _get(
        InventoryEndpoints.residences,
        InventoryMapper.residencesFrom,
        query: const {'page': 1, 'limit': _optionsLimit},
      );

  // ---- Stock counts ----

  @override
  Future<Result<InventoryListPage<StockCount>>> stockCounts({
    required int page,
    required int limit,
  }) =>
      _get(
        InventoryEndpoints.stockCounts,
        InventoryMapper.countPageFrom,
        query: {'page': page, 'limit': limit},
      );

  @override
  Future<Result<StockCount>> stockCount(String id) async {
    final result = await _api.get(InventoryEndpoints.stockCount(id), silent: true);
    return result.when(
      success: (body) {
        final count = InventoryMapper.countFrom(JsonCodec.unwrapMap(body));
        return count == null
            ? Result.failure(const ApiError(message: 'Count could not be read'))
            : Result.success(count);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<StockCountOpened>> openStockCount({
    required String residenceId,
    String? categoryId,
  }) async {
    final result = await _api.post(
      InventoryEndpoints.stockCounts,
      data: {'residenceId': residenceId, 'categoryId': ?categoryId},
      silent: true,
      allowQueue: false,
    );
    final opened = result.when<StockCountOpened?>(
      success: (body) => switch (JsonCodec.string(JsonCodec.unwrapMap(body)['id'])) {
        final id? => StockCountOpened(id: id),
        null => null,
      },
      failure: (_) => null,
    );
    if (opened != null) return Result.success(opened);
    final error = result.error ?? const ApiError(message: 'Count could not be opened');
    // The API refuses a second open count on the same shelves
    // (STOCK_COUNT_OPEN); the client drops its details, so find the draft.
    if (error is ApiError) {
      final existing = await _openDraft(residenceId, categoryId);
      if (existing != null) {
        return Result.success(StockCountOpened(id: existing, alreadyOpen: true));
      }
    }
    return Result.failure(error);
  }

  Future<String?> _openDraft(String residenceId, String? categoryId) async {
    final result = await _api.get(
      InventoryEndpoints.stockCounts,
      query: const {'page': 1, 'limit': _optionsLimit},
      silent: true,
    );
    return result.when(
      success: (body) {
        for (final row in JsonCodec.unwrapList(body).whereType<Map>()) {
          final json = JsonCodec.asMap(row);
          if (JsonCodec.string(json['status']) == StockCount.editableStatus &&
              JsonCodec.string(json['residenceId']) == residenceId &&
              JsonCodec.string(json['categoryId']) == categoryId) {
            return JsonCodec.string(json['id']);
          }
        }
        return null;
      },
      failure: (_) => null,
    );
  }

  @override
  Future<Result<void>> saveCountLines(String id, List<Map<String, dynamic>> lines) =>
      _patch(InventoryEndpoints.stockCountLines(id), {'lines': lines});

  @override
  Future<Result<void>> submitCount(String id) =>
      _post(InventoryEndpoints.stockCountSubmit(id));

  @override
  Future<Result<void>> cancelCount(String id) =>
      _post(InventoryEndpoints.stockCountCancel(id));

  // ---- Transfers ----

  @override
  Future<Result<InventoryListPage<StockTransfer>>> transfers({
    required int page,
    required int limit,
  }) =>
      _get(
        InventoryEndpoints.stockTransfers,
        InventoryMapper.transferPageFrom,
        query: {'page': page, 'limit': limit},
      );

  @override
  Future<Result<void>> createTransfer(Map<String, dynamic> body) =>
      _post(InventoryEndpoints.stockTransfers, body);

  @override
  Future<Result<void>> approveTransfer(String id) =>
      _post(InventoryEndpoints.stockTransferApprove(id));

  @override
  Future<Result<void>> dispatchTransfer(String id, List<Map<String, dynamic>> lines) =>
      _post(InventoryEndpoints.stockTransferDispatch(id), {'lines': lines});

  @override
  Future<Result<void>> receiveTransfer(String id, List<Map<String, dynamic>> lines) =>
      _post(InventoryEndpoints.stockTransferReceive(id), {'lines': lines});

  @override
  Future<Result<void>> cancelTransfer(String id) =>
      _post(InventoryEndpoints.stockTransferCancel(id));

  // ---- Purchasing ----

  @override
  Future<Result<InventoryListPage<InventorySupplier>>> suppliers({
    required int page,
    required int limit,
  }) =>
      _get(
        InventoryEndpoints.suppliers,
        InventoryMapper.supplierPageFrom,
        query: {'page': page, 'limit': limit},
      );

  @override
  Future<Result<void>> createSupplier({required String name, required String category}) =>
      _post(InventoryEndpoints.suppliers, {'name': name, 'category': category});

  @override
  Future<Result<void>> removeSupplier(String id) => _delete(InventoryEndpoints.supplier(id));

  @override
  Future<Result<void>> restoreSupplier(String id) =>
      _post(InventoryEndpoints.supplierRestore(id));

  @override
  Future<Result<InventoryListPage<PurchaseOrder>>> purchaseOrders({
    required int page,
    required int limit,
  }) =>
      _get(
        InventoryEndpoints.purchaseOrders,
        InventoryMapper.orderPageFrom,
        query: {'page': page, 'limit': limit},
      );

  @override
  Future<Result<void>> createOrder(Map<String, dynamic> body) =>
      _post(InventoryEndpoints.purchaseOrders, body);

  @override
  Future<Result<void>> updateOrder(String id, Map<String, dynamic> body) =>
      _patch(InventoryEndpoints.purchaseOrder(id), body);

  @override
  Future<Result<void>> submitOrder(String id) =>
      _post(InventoryEndpoints.purchaseOrderSubmit(id));

  @override
  Future<Result<void>> requestOrderApproval(String id) =>
      _post(InventoryEndpoints.purchaseOrderRequestApproval(id));

  @override
  Future<Result<void>> approveOrder(String id) =>
      _post(InventoryEndpoints.purchaseOrderApprove(id));

  @override
  Future<Result<void>> rejectOrder(String id, String reason) =>
      _post(InventoryEndpoints.purchaseOrderReject(id), {'reason': reason});

  @override
  Future<Result<void>> receiveOrder(String id, Map<String, dynamic> body) =>
      _post(InventoryEndpoints.purchaseOrderReceive(id), body);

  @override
  Future<Result<void>> cancelOrder(String id) =>
      _post(InventoryEndpoints.purchaseOrderCancel(id));
}
