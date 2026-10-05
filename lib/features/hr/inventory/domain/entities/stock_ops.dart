/// One shelf line of a stock count.
class StockCountLine {
  final String id;
  final String? itemName;
  final String? itemUnit;
  final String? batchNo;
  final String? batchExpiry;
  final bool hasBatch;
  final num systemQty;
  final num? countedQty;

  const StockCountLine({
    required this.id,
    this.itemName,
    this.itemUnit,
    this.batchNo,
    this.batchExpiry,
    this.hasBatch = false,
    this.systemQty = 0,
    this.countedQty,
  });
}

/// A `/stock-counts` row.
class StockCount {
  final String id;
  final String residenceId;
  final String? residenceName;
  final String status;
  final int varianceCount;
  final List<StockCountLine> lines;
  final DateTime? createdAt;

  const StockCount({
    required this.id,
    required this.residenceId,
    required this.status,
    this.residenceName,
    this.varianceCount = 0,
    this.lines = const [],
    this.createdAt,
  });

  static const String editableStatus = 'draft';

  bool get isEditable => status == editableStatus;
}

class StockTransferLine {
  final String id;
  final String? itemName;
  final num quantity;
  final num? dispatchedQuantity;
  final num? receivedQuantity;

  const StockTransferLine({
    required this.id,
    this.itemName,
    this.quantity = 0,
    this.dispatchedQuantity,
    this.receivedQuantity,
  });
}

/// A `/stock-transfers` row.
class StockTransfer {
  final String id;
  final String? reference;
  final String status;
  final String? notes;
  final String fromResidenceId;
  final String toResidenceId;
  final String? fromResidenceName;
  final String? toResidenceName;
  final List<StockTransferLine> lines;

  const StockTransfer({
    required this.id,
    required this.status,
    required this.fromResidenceId,
    required this.toResidenceId,
    this.reference,
    this.notes,
    this.fromResidenceName,
    this.toResidenceName,
    this.lines = const [],
  });

  static const Map<String, List<String>> transitions = {
    'approve': ['requested'],
    'dispatch': ['approved', 'partially_dispatched'],
    'receive': ['dispatched', 'partially_dispatched'],
    'cancel': ['requested', 'approved'],
  };

  /// The forward steps (approve / dispatch / receive) open from [status].
  List<String> get nextSteps => [
        for (final entry in transitions.entries)
          if (entry.key != 'cancel' && entry.value.contains(status)) entry.key,
      ];

  bool get canCancel => transitions['cancel']!.contains(status);
}
