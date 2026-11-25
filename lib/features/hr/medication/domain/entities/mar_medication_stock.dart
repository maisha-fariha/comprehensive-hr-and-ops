import 'package:flutter/foundation.dart';

/// One row from `GET /medication-stock` (trolley count for a prescription).
@immutable
class MarMedicationStock {
  final String id;
  final String residenceId;
  final String? medicationId;
  final String? prnMedicationId;
  final num quantity;
  final String? unit;
  final num? refillThreshold;
  final bool needsRefill;
  final DateTime? updatedAt;

  const MarMedicationStock({
    required this.id,
    required this.residenceId,
    this.medicationId,
    this.prnMedicationId,
    required this.quantity,
    this.unit,
    this.refillThreshold,
    this.needsRefill = false,
    this.updatedAt,
  });
}

/// Body for `PUT /medication-stock` (web "Count stock" / `setStock`).
@immutable
class MarStockCountDraft {
  final String residenceId;
  final String? medicationId;
  final String? prnMedicationId;
  final num quantity;
  final String? unit;
  final num? refillThreshold;

  const MarStockCountDraft({
    required this.residenceId,
    this.medicationId,
    this.prnMedicationId,
    required this.quantity,
    this.unit,
    this.refillThreshold,
  });
}

/// Joined Stock-tab row: active scheduled/PRN medicine + optional count.
@immutable
class MarStockRow {
  final String key;
  final String? medicationId;
  final String? prnMedicationId;
  final String residenceId;
  final String residenceName;
  final String name;
  final String kind;
  final String resident;
  final int? unitsPerDose;
  final MarMedicationStock? stock;

  const MarStockRow({
    required this.key,
    this.medicationId,
    this.prnMedicationId,
    required this.residenceId,
    required this.residenceName,
    required this.name,
    required this.kind,
    required this.resident,
    this.unitsPerDose,
    this.stock,
  });

  bool get isPrn => prnMedicationId != null && prnMedicationId!.isNotEmpty;
}
