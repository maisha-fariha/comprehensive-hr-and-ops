/// Paths behind web `/dashboard/inventory`, `/inventory/counts`,
/// `/inventory/transfers` and `/dashboard/purchasing`.
abstract final class InventoryEndpoints {
  static const String residences = '/residences';

  static const String items = '/inventory/items';
  static String item(String id) => '$items/$id';
  static String itemRestore(String id) => '$items/$id/restore';
  static String itemAdjust(String id) => '$items/$id/adjust';
  static String itemTransactions(String id) => '$items/$id/transactions';
  static String itemBatches(String id) => '$items/$id/batches';
  static String itemBatch(String id, String batchId) => '$items/$id/batches/$batchId';
  static String itemCostHistory(String id) => '$items/$id/cost-history';
  static String itemSuppliers(String id) => '$items/$id/suppliers';
  static String itemSupplier(String id, String linkId) => '$items/$id/suppliers/$linkId';

  static const String transactions = '/inventory/transactions';
  static const String expiringBatches = '/inventory/batches/expiring';
  static const String exceptions = '/inventory/exceptions';

  static const String categories = '/inventory-categories';
  static String category(String id) => '$categories/$id';
  static String categoryArchive(String id, bool archive) =>
      '$categories/$id/${archive ? 'archive' : 'restore'}';

  static const String unitTypes = '/unit-types';
  static String unitType(String id) => '$unitTypes/$id';
  static String unitTypeArchive(String id, bool archive) =>
      '$unitTypes/$id/${archive ? 'archive' : 'restore'}';

  static const String stockCounts = '/stock-counts';
  static String stockCount(String id) => '$stockCounts/$id';
  static String stockCountLines(String id) => '$stockCounts/$id/lines';
  static String stockCountSubmit(String id) => '$stockCounts/$id/submit';
  static String stockCountCancel(String id) => '$stockCounts/$id/cancel';

  static const String stockTransfers = '/stock-transfers';
  static String stockTransfer(String id) => '$stockTransfers/$id';
  static String stockTransferApprove(String id) => '$stockTransfers/$id/approve';
  static String stockTransferDispatch(String id) => '$stockTransfers/$id/dispatch';
  static String stockTransferReceive(String id) => '$stockTransfers/$id/receive';
  static String stockTransferCancel(String id) => '$stockTransfers/$id/cancel';

  static const String suppliers = '/suppliers';
  static String supplier(String id) => '$suppliers/$id';
  static String supplierRestore(String id) => '$suppliers/$id/restore';

  static const String purchaseOrders = '/purchase-orders';
  static String purchaseOrder(String id) => '$purchaseOrders/$id';
  static String purchaseOrderSubmit(String id) => '$purchaseOrders/$id/submit';
  static String purchaseOrderRequestApproval(String id) =>
      '$purchaseOrders/$id/request-approval';
  static String purchaseOrderApprove(String id) => '$purchaseOrders/$id/approve';
  static String purchaseOrderReject(String id) => '$purchaseOrders/$id/reject';
  static String purchaseOrderReceive(String id) => '$purchaseOrders/$id/receive';
  static String purchaseOrderCancel(String id) => '$purchaseOrders/$id/cancel';
}
