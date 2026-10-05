import 'package:flutter/foundation.dart';

/// One witness account on Incident Details
/// (`GET /incidents/:id/witness-statements`).
@immutable
class IncidentWitnessStatement {
  /// Web "Who is speaking" options.
  static const Map<String, String> witnessTypes = {
    'staff': 'Staff member',
    'resident': 'Resident',
    'visitor': 'Visitor',
  };

  final String id;
  final String witnessType;
  final String witnessName;
  final String statementText;
  final String? takenByName;
  final DateTime? signedAt;

  const IncidentWitnessStatement({
    required this.id,
    required this.witnessType,
    required this.witnessName,
    required this.statementText,
    this.takenByName,
    this.signedAt,
  });

  bool get isSigned => signedAt != null;

  /// "Staff member · taken by Jane Doe", like the web row subtitle.
  String get subtitle {
    final type = witnessTypes[witnessType] ?? witnessType;
    final taker = takenByName?.trim() ?? '';
    return taker.isEmpty ? type : '$type · taken by $taker';
  }
}
