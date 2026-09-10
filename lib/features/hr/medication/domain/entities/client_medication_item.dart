import 'package:flutter/foundation.dart';

/// A prescribed or PRN medication for a client
/// (`GET /medications?clientId=` / `GET /prn-medications?clientId=`).
@immutable
class ClientMedicationItem {
  final String id;
  final String name;
  final String dose;
  final String? scheduleLabel;
  final String? instructions;
  final bool isPrn;

  const ClientMedicationItem({
    required this.id,
    required this.name,
    required this.dose,
    this.scheduleLabel,
    this.instructions,
    this.isPrn = false,
  });
}
