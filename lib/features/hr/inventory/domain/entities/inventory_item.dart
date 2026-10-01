/// A value + label pair for pickers (residences, categories, units, suppliers).
class InventoryOption {
  final String value;
  final String label;

  const InventoryOption({required this.value, required this.label});
}

/// An `/inventory/items` row.
class InventoryItem {
  final String id;
  final String name;
  final String residenceId;
  final String? residenceName;
  final String? categoryId;
  final String? categoryName;
  final String? sku;
  final num quantity;
  final String? unit;
  final num? reorderLevel;
  final bool tracksBatches;
  final String? itemType;
  final String? supplierName;
  final num? costPerUnit;
  final num? averageUnitCost;
  final num? lastUnitCost;
  final num? stockValue;
  final String? remark;
  final DateTime? deletedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.residenceId,
    this.residenceName,
    this.categoryId,
    this.categoryName,
    this.sku,
    this.quantity = 0,
    this.unit,
    this.reorderLevel,
    this.tracksBatches = false,
    this.itemType,
    this.supplierName,
    this.costPerUnit,
    this.averageUnitCost,
    this.lastUnitCost,
    this.stockValue,
    this.remark,
    this.deletedAt,
  });

  /// Web `stockState`: out at zero or below, low at or below the reorder level.
  InventoryStockState get stockState {
    if (quantity <= 0) return InventoryStockState.out;
    final level = reorderLevel;
    if (level != null && quantity <= level) return InventoryStockState.low;
    return InventoryStockState.ok;
  }

  String get unitLabel => unit ?? '';
}

enum InventoryStockState { ok, low, out }

/// `meta.summary` of the item list, the source of the five KPI tiles.
class InventorySummary {
  final int items;
  final int lowStock;
  final int outOfStock;
  final int watched;
  final num value;
  final int unpriced;

  const InventorySummary({
    this.items = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
    this.watched = 0,
    this.value = 0,
    this.unpriced = 0,
  });
}

class InventoryListPage<T> {
  final List<T> items;
  final int total;

  const InventoryListPage({required this.items, required this.total});
}

class InventoryItemPage extends InventoryListPage<InventoryItem> {
  final InventorySummary summary;

  const InventoryItemPage({
    required super.items,
    required super.total,
    this.summary = const InventorySummary(),
  });
}

/// A dated lot of a batch-tracked item. [itemName] / [itemUnit] are only
/// filled on `/inventory/batches/expiring`.
class InventoryBatch {
  final String id;
  final String? batchNo;
  final num? quantity;
  final String? expiryDate;
  final num? unitCost;
  final String? itemName;
  final String? itemUnit;

  const InventoryBatch({
    required this.id,
    this.batchNo,
    this.quantity,
    this.expiryDate,
    this.unitCost,
    this.itemName,
    this.itemUnit,
  });

  /// `YYYY-MM-DD` part of [expiryDate].
  String? get expiryDay {
    final raw = expiryDate;
    if (raw == null || raw.length < 10) return raw;
    return raw.substring(0, 10);
  }

  /// Whole days from today (UTC) to the expiry date; negative once past it.
  int? daysLeft({DateTime? now}) {
    final day = expiryDay;
    if (day == null) return null;
    final expiry = DateTime.tryParse('${day}T00:00:00.000Z');
    if (expiry == null) return null;
    final today = (now ?? DateTime.now()).toUtc();
    final midnight = DateTime.utc(today.year, today.month, today.day);
    return (expiry.difference(midnight).inHours / 24).round();
  }
}

/// One `/inventory/transactions` entry.
class StockMovement {
  final String id;
  final String? itemName;
  final String? unit;
  final String? residenceName;
  final String type;
  final num changeQty;
  final num? previousQty;
  final num? newQty;
  final String? reason;
  final String? performedByName;
  final DateTime? createdAt;

  const StockMovement({
    required this.id,
    required this.type,
    required this.changeQty,
    this.itemName,
    this.unit,
    this.residenceName,
    this.previousQty,
    this.newQty,
    this.reason,
    this.performedByName,
    this.createdAt,
  });
}

/// An `/inventory/exceptions` row ("Recent losses").
class InventoryLoss {
  final String id;
  final String? itemName;
  final String? unit;
  final String? residenceName;
  final String exceptionType;
  final num? quantity;
  final String? notes;
  final String? loggedByName;
  final DateTime? createdAt;

  const InventoryLoss({
    required this.id,
    required this.exceptionType,
    this.itemName,
    this.unit,
    this.residenceName,
    this.quantity,
    this.notes,
    this.loggedByName,
    this.createdAt,
  });
}

/// A purchase-order line for the item ("What it has cost").
class InventoryCostEntry {
  final String purchaseOrderId;
  final String? reference;
  final String? supplierName;
  final num? quantity;
  final num? receivedQuantity;
  final String? unit;
  final num? unitCost;
  final String? orderedAt;
  final String? receivedAt;

  const InventoryCostEntry({
    required this.purchaseOrderId,
    this.reference,
    this.supplierName,
    this.quantity,
    this.receivedQuantity,
    this.unit,
    this.unitCost,
    this.orderedAt,
    this.receivedAt,
  });
}

/// A supplier linked to an item ("Who can supply this").
class InventoryItemSupplier {
  final String id;
  final String supplierId;
  final String? supplierName;
  final String? supplierSku;
  final num? unitCost;
  final int? leadTimeDays;
  final bool isPreferred;

  const InventoryItemSupplier({
    required this.id,
    required this.supplierId,
    this.supplierName,
    this.supplierSku,
    this.unitCost,
    this.leadTimeDays,
    this.isPreferred = false,
  });
}

/// An inventory category or unit type. Units carry a [code].
class InventoryCatalogueEntry {
  final String id;
  final String name;
  final String? code;
  final bool isActive;

  const InventoryCatalogueEntry({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
  });
}
