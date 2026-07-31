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

  const AttentionAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
  });
}
