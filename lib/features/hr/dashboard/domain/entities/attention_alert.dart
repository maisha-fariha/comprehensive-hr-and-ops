import 'package:flutter/foundation.dart';

import 'dashboard_enums.dart';

/// A single row in the "Needs Attention" card, e.g. an open incident or an
/// understaffed shift that requires the manager's action.
@immutable
class AttentionAlert {
  final String id;
  final String title;
  final String subtitle;
  final AlertSeverity severity;

  /// API `type` (`incident_open`, `document_expired`, …).
  final String? type;

  /// API `meta` payload (`incidentId`, `documentId`, …).
  final Map<String, dynamic> meta;

  const AttentionAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
    this.type,
    this.meta = const {},
  });

  String? metaString(String key) {
    final value = meta[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}
