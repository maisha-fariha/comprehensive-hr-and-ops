import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/purchasing.dart';
import '../../domain/entities/stock_ops.dart';

class InventoryMapper {
  const InventoryMapper._();

  static Iterable<Map<String, dynamic>> _rows(dynamic body) =>
      JsonCodec.unwrapList(body).whereType<Map>().map(JsonCodec.asMap);

  static int _total(dynamic body, int fallback) =>
      JsonCodec.integer(JsonCodec.metaOf(body)?['total']) ?? fallback;

  static String? _nameOf(Map<String, dynamic> json, String key) =>
      JsonCodec.string(JsonCodec.mapAt(json, key)?['name']);

  static InventoryItem? itemFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final name = JsonCodec.string(json['name']);
    if (id == null || name == null) return null;
    return InventoryItem(
      id: id,
      name: name,
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      residenceName: _nameOf(json, 'residence'),
      categoryId: JsonCodec.string(json['categoryId']),
      categoryName: _nameOf(json, 'category'),
      sku: JsonCodec.string(json['sku']),
      quantity: JsonCodec.number(json['quantity']) ?? 0,
      unit: JsonCodec.string(json['unit']),
      reorderLevel: JsonCodec.number(json['reorderLevel']),
      tracksBatches: JsonCodec.boolean(json['tracksBatches']) ?? false,
      itemType: JsonCodec.string(json['itemType']),
      supplierName: JsonCodec.string(json['supplierName']),
      costPerUnit: JsonCodec.number(json['costPerUnit']),
      averageUnitCost: JsonCodec.number(json['averageUnitCost']),
      lastUnitCost: JsonCodec.number(json['lastUnitCost']),
      stockValue: JsonCodec.number(json['stockValue']),
      remark: JsonCodec.string(json['remark']),
      deletedAt: JsonCodec.dateTime(json['deletedAt']),
    );
  }

  static InventorySummary summaryFrom(Map<String, dynamic>? json) {
    if (json == null) return const InventorySummary();
    return InventorySummary(
      items: JsonCodec.integerOr(json['items'], 0),
      lowStock: JsonCodec.integerOr(json['lowStock'], 0),
      outOfStock: JsonCodec.integerOr(json['outOfStock'], 0),
      watched: JsonCodec.integerOr(json['watched'], 0),
      value: JsonCodec.number(json['value']) ?? 0,
      unpriced: JsonCodec.integerOr(json['unpriced'], 0),
    );
  }

  static InventoryItemPage itemPageFrom(dynamic body) {
    final items = [for (final row in _rows(body)) ?itemFrom(row)];
    final meta = JsonCodec.metaOf(body);
    final summary = meta?['summary'];
    return InventoryItemPage(
      items: items,
      total: _total(body, items.length),
      summary: summaryFrom(summary is Map ? JsonCodec.asMap(summary) : null),
    );
  }

  static InventoryBatch? batchFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    final item = JsonCodec.mapAt(json, 'item');
    return InventoryBatch(
      id: id,
      batchNo: JsonCodec.string(json['batchNo']),
      quantity: JsonCodec.number(json['quantity']),
      expiryDate: JsonCodec.string(json['expiryDate']),
      unitCost: JsonCodec.number(json['unitCost']),
      itemName: JsonCodec.string(item?['name']),
      itemUnit: JsonCodec.string(item?['unit']),
    );
  }

  static List<InventoryBatch> batchesFrom(dynamic body) =>
      [for (final row in _rows(body)) ?batchFrom(row)];

  static StockMovement? movementFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final type = JsonCodec.string(json['type']);
    if (id == null || type == null) return null;
    return StockMovement(
      id: id,
      type: type,
      changeQty: JsonCodec.number(json['changeQty']) ?? 0,
      itemName: JsonCodec.string(json['itemName']),
      unit: JsonCodec.string(json['unit']),
      residenceName: JsonCodec.string(json['residenceName']),
      previousQty: JsonCodec.number(json['previousQty']),
      newQty: JsonCodec.number(json['newQty']),
      reason: JsonCodec.string(json['reason']),
      performedByName: JsonCodec.string(json['performedByName']),
      createdAt: JsonCodec.dateTime(json['createdAt']),
    );
  }

  static List<StockMovement> movementsFrom(dynamic body) =>
      [for (final row in _rows(body)) ?movementFrom(row)];

  static List<InventoryLoss> lossesFrom(dynamic body) => [
        for (final row in _rows(body))
          if (JsonCodec.string(row['id']) case final id?)
            InventoryLoss(
              id: id,
              exceptionType: JsonCodec.stringOr(row['exceptionType'], 'waste'),
              itemName: JsonCodec.string(row['itemName']),
              unit: JsonCodec.string(row['unit']),
              residenceName: JsonCodec.string(row['residenceName']),
              quantity: JsonCodec.number(row['quantity']),
              notes: JsonCodec.string(row['notes']),
              loggedByName: JsonCodec.string(row['loggedByName']),
              createdAt: JsonCodec.dateTime(row['createdAt']),
            ),
      ];

  static List<InventoryCostEntry> costHistoryFrom(dynamic body) => [
        for (final row in _rows(body))
          if (JsonCodec.string(row['purchaseOrderId']) case final id?)
            InventoryCostEntry(
              purchaseOrderId: id,
              reference: JsonCodec.string(row['reference']),
              supplierName: _nameOf(row, 'supplier'),
              quantity: JsonCodec.number(row['quantity']),
              receivedQuantity: JsonCodec.number(row['receivedQuantity']),
              unit: JsonCodec.string(row['unit']),
              unitCost: JsonCodec.number(row['unitCost']),
              orderedAt: JsonCodec.string(row['orderedAt']),
              receivedAt: JsonCodec.string(row['receivedAt']),
            ),
      ];

  static List<InventoryItemSupplier> itemSuppliersFrom(dynamic body) => [
        for (final row in _rows(body))
          if ((JsonCodec.string(row['id']), JsonCodec.string(row['supplierId']))
              case (final id?, final supplierId?))
            InventoryItemSupplier(
              id: id,
              supplierId: supplierId,
              supplierName: _nameOf(row, 'supplier'),
              supplierSku: JsonCodec.string(row['supplierSku']),
              unitCost: JsonCodec.number(row['unitCost']),
              leadTimeDays: JsonCodec.integer(row['leadTimeDays']),
              isPreferred: JsonCodec.boolean(row['isPreferred']) ?? false,
            ),
      ];

  static List<InventoryCatalogueEntry> catalogueFrom(dynamic body) => [
        for (final row in _rows(body))
          if ((JsonCodec.string(row['id']), JsonCodec.string(row['name']))
              case (final id?, final name?))
            InventoryCatalogueEntry(
              id: id,
              name: name,
              code: JsonCodec.string(row['code']),
              isActive: JsonCodec.boolean(row['isActive']) ?? true,
            ),
      ];

  static List<InventoryOption> residencesFrom(dynamic body) => [
        for (final row in _rows(body))
          if (JsonCodec.string(row['id']) case final id?)
            InventoryOption(value: id, label: JsonCodec.stringOr(row['name'], 'Residence')),
      ];

  static StockCount? countFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return StockCount(
      id: id,
      residenceId: JsonCodec.stringOr(json['residenceId'], ''),
      residenceName: _nameOf(json, 'residence'),
      status: JsonCodec.stringOr(json['status'], 'draft'),
      varianceCount: JsonCodec.integerOr(json['varianceCount'], 0),
      createdAt: JsonCodec.dateTime(json['createdAt']),
      lines: [
        for (final raw in JsonCodec.listAt(json, 'lines').whereType<Map>())
          if (JsonCodec.string(raw['id']) case final lineId?)
            _countLine(lineId, JsonCodec.asMap(raw)),
      ],
    );
  }

  static StockCountLine _countLine(String id, Map<String, dynamic> json) {
    final item = JsonCodec.mapAt(json, 'item');
    final batch = JsonCodec.mapAt(json, 'batch');
    return StockCountLine(
      id: id,
      itemName: JsonCodec.string(item?['name']),
      itemUnit: JsonCodec.string(item?['unit']),
      hasBatch: batch != null,
      batchNo: JsonCodec.string(batch?['batchNo']),
      batchExpiry: JsonCodec.string(batch?['expiryDate']),
      systemQty: JsonCodec.number(json['systemQty']) ?? 0,
      countedQty: JsonCodec.number(json['countedQty']),
    );
  }

  static InventoryListPage<StockCount> countPageFrom(dynamic body) {
    final items = [for (final row in _rows(body)) ?countFrom(row)];
    return InventoryListPage(items: items, total: _total(body, items.length));
  }

  static StockTransfer? transferFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return StockTransfer(
      id: id,
      reference: JsonCodec.string(json['reference']),
      status: JsonCodec.stringOr(json['status'], 'requested'),
      notes: JsonCodec.string(json['notes']),
      fromResidenceId: JsonCodec.stringOr(json['fromResidenceId'], ''),
      toResidenceId: JsonCodec.stringOr(json['toResidenceId'], ''),
      fromResidenceName: _nameOf(json, 'fromResidence'),
      toResidenceName: _nameOf(json, 'toResidence'),
      lines: [
        for (final raw in JsonCodec.listAt(json, 'lines').whereType<Map>())
          if (JsonCodec.string(raw['id']) case final lineId?)
            StockTransferLine(
              id: lineId,
              itemName: _nameOf(JsonCodec.asMap(raw), 'item'),
              quantity: JsonCodec.number(raw['quantity']) ?? 0,
              dispatchedQuantity: JsonCodec.number(raw['dispatchedQuantity']),
              receivedQuantity: JsonCodec.number(raw['receivedQuantity']),
            ),
      ],
    );
  }

  static InventoryListPage<StockTransfer> transferPageFrom(dynamic body) {
    final items = [for (final row in _rows(body)) ?transferFrom(row)];
    return InventoryListPage(items: items, total: _total(body, items.length));
  }

  static InventorySupplier? supplierFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    final name = JsonCodec.string(json['name']);
    if (id == null || name == null) return null;
    return InventorySupplier(
      id: id,
      name: name,
      residenceId: JsonCodec.string(json['residenceId']),
      category: JsonCodec.string(json['category']),
      contactName: JsonCodec.string(json['contactName']),
      email: JsonCodec.string(json['email']),
      phone: JsonCodec.string(json['phone']),
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
      deletedAt: JsonCodec.dateTime(json['deletedAt']),
    );
  }

  static InventoryListPage<InventorySupplier> supplierPageFrom(dynamic body) {
    final items = [for (final row in _rows(body)) ?supplierFrom(row)];
    return InventoryListPage(items: items, total: _total(body, items.length));
  }

  static PurchaseOrder? orderFrom(Map<String, dynamic> json) {
    final id = JsonCodec.string(json['id']);
    if (id == null) return null;
    return PurchaseOrder(
      id: id,
      reference: JsonCodec.string(json['reference']),
      status: JsonCodec.stringOr(json['status'], 'draft'),
      residenceId: JsonCodec.string(json['residenceId']),
      residenceName: _nameOf(json, 'residence'),
      supplierId: JsonCodec.string(json['supplierId']),
      supplierName: _nameOf(json, 'supplier'),
      notes: JsonCodec.string(json['notes']),
      expectedAt: JsonCodec.string(json['expectedAt']),
      rejectionReason: JsonCodec.string(json['rejectionReason']),
      items: [
        for (final raw in JsonCodec.listAt(json, 'items').whereType<Map>())
          if (JsonCodec.string(raw['id']) case final lineId?)
            _orderLine(lineId, JsonCodec.asMap(raw)),
      ],
    );
  }

  static PurchaseOrderLine _orderLine(String id, Map<String, dynamic> json) {
    final item = JsonCodec.mapAt(json, 'inventoryItem');
    final itemId = JsonCodec.string(item?['id']);
    final itemName = JsonCodec.string(item?['name']);
    return PurchaseOrderLine(
      id: id,
      description: JsonCodec.string(json['description']),
      quantity: JsonCodec.number(json['quantity']),
      receivedQuantity: JsonCodec.number(json['receivedQuantity']),
      unitCost: JsonCodec.number(json['unitCost']),
      lineTotal: JsonCodec.number(json['lineTotal']),
      unit: JsonCodec.string(json['unit']),
      inventoryItem: itemId == null || itemName == null
          ? null
          : PurchaseOrderLineItem(
              id: itemId,
              name: itemName,
              unit: JsonCodec.string(item?['unit']),
              tracksBatches: JsonCodec.boolean(item?['tracksBatches']) ?? false,
            ),
    );
  }

  static InventoryListPage<PurchaseOrder> orderPageFrom(dynamic body) {
    final items = [for (final row in _rows(body)) ?orderFrom(row)];
    return InventoryListPage(items: items, total: _total(body, items.length));
  }
}
