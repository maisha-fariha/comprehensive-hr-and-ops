/// A `/suppliers` row.
class InventorySupplier {
  final String id;
  final String name;
  final String? residenceId;
  final String? category;
  final String? contactName;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime? deletedAt;

  const InventorySupplier({
    required this.id,
    required this.name,
    this.residenceId,
    this.category,
    this.contactName,
    this.email,
    this.phone,
    this.isActive = true,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
}

/// The stock item a purchase-order line restocks.
class PurchaseOrderLineItem {
  final String id;
  final String name;
  final String? unit;
  final bool tracksBatches;

  const PurchaseOrderLineItem({
    required this.id,
    required this.name,
    this.unit,
    this.tracksBatches = false,
  });
}

class PurchaseOrderLine {
  final String id;
  final String? description;
  final num? quantity;
  final num? receivedQuantity;
  final num? unitCost;
  final num? lineTotal;
  final String? unit;
  final PurchaseOrderLineItem? inventoryItem;

  const PurchaseOrderLine({
    required this.id,
    this.description,
    this.quantity,
    this.receivedQuantity,
    this.unitCost,
    this.lineTotal,
    this.unit,
    this.inventoryItem,
  });
}

/// A `/purchase-orders` row.
class PurchaseOrder {
  final String id;
  final String? reference;
  final String status;
  final String? residenceId;
  final String? residenceName;
  final String? supplierId;
  final String? supplierName;
  final String? notes;
  final String? expectedAt;
  final String? rejectionReason;
  final List<PurchaseOrderLine> items;

  const PurchaseOrder({
    required this.id,
    required this.status,
    this.reference,
    this.residenceId,
    this.residenceName,
    this.supplierId,
    this.supplierName,
    this.notes,
    this.expectedAt,
    this.rejectionReason,
    this.items = const [],
  });

  static const Map<String, List<String>> transitions = {
    'submit': ['draft'],
    'requestApproval': ['draft'],
    'approve': ['pending_approval'],
    'reject': ['pending_approval'],
    'receive': ['submitted', 'partially_received'],
    'cancel': ['draft', 'submitted', 'pending_approval', 'partially_received'],
    'edit': ['draft'],
  };

  bool allows(String action) => transitions[action]?.contains(status) ?? false;

  /// Submitting needs a supplier.
  bool get canSubmit => allows('submit') && supplierId != null;

  /// Sum of the priced lines; null when nothing is priced.
  num? get total {
    final priced = items.where((l) => l.lineTotal != null).toList();
    if (priced.isEmpty) return null;
    return priced.fold<num>(0, (sum, l) => sum + l.lineTotal!);
  }

  num get orderedUnits => items.fold<num>(0, (sum, l) => sum + (l.quantity ?? 0));

  num get receivedUnits =>
      items.fold<num>(0, (sum, l) => sum + (l.receivedQuantity ?? 0));

  String get displayReference =>
      reference ?? '#${id.length > 8 ? id.substring(0, 8) : id}';
}
