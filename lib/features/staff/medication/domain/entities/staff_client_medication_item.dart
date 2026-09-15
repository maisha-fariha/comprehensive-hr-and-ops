import 'package:flutter/foundation.dart';

/// Prescribed or PRN medication for a client
/// (`GET /medications?clientId=` / `GET /prn-medications?clientId=`).
@immutable
class StaffClientMedicationItem {
  final String id;
  final String name;
  final String dose;
  final String? scheduleLabel;
  final String? instructions;
  final bool isPrn;

  const StaffClientMedicationItem({
    required this.id,
    required this.name,
    required this.dose,
    this.scheduleLabel,
    this.instructions,
    this.isPrn = false,
  });
}
