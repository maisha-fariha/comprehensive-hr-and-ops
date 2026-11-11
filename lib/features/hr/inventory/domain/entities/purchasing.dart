/// A `/suppliers` row.
class InventorySupplier {
  final String id;
  final String name;
  final String? residenceId;
  final String? category;
  final String? contactName;
  final String? email;
  final String? phone;
  final String? address;
  /// Printed on purchase orders so the supplier can match them.
  final String? accountRef;
  final String? notes;
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
    this.address,
    this.accountRef,
    this.notes,
    this.isActive = true,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  bool get hasContact =>
      (email != null && email!.trim().isNotEmpty) ||
      (phone != null && phone!.trim().isNotEmpty);
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
  final String? supplierEmail;
  final String? supplierPhone;
  final String? notes;
  final String? expectedAt;
  final DateTime? createdAt;
  final String? rejectionReason;
  /// When the order was emailed / marked placed (`sentAt` / `sentVia` / `sentTo`).
  final DateTime? sentAt;
  final String? sentVia;
  final String? sentTo;
  final List<PurchaseOrderLine> items;

  const PurchaseOrder({
    required this.id,
    required this.status,
    this.reference,
    this.residenceId,
    this.residenceName,
    this.supplierId,
    this.supplierName,
    this.supplierEmail,
    this.supplierPhone,
    this.notes,
    this.expectedAt,
    this.createdAt,
    this.rejectionReason,
    this.sentAt,
    this.sentVia,
    this.sentTo,
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
    'send': ['submitted', 'partially_received'],
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

  /// Web status caption under Submitted, e.g. "Emailed to a@b.com".
  String? get sentCaption {
    final via = (sentVia ?? '').toLowerCase();
    if (via == 'email') {
      final to = (sentTo ?? supplierEmail)?.trim();
      if (to != null && to.isNotEmpty) return 'Emailed to $to';
      return 'Emailed to supplier';
    }
    if (via == 'manual' || via == 'phone') {
      return 'Placed by phone / website.';
    }
    return null;
  }

  /// Web fulfillment strip when nothing has been emailed / marked placed.
  String get sendStatusLabel {
    final caption = sentCaption;
    if (caption != null) return caption;
    return 'Not yet sent to supplier';
  }

  bool get canResend => allows('send') && (sentVia == 'email' || sentAt != null);
}
