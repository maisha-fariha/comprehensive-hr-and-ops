import 'package:flutter/foundation.dart';

import 'family_dashboard_enums.dart';

/// A single row in the "Needs Attention" card, e.g. an open incident or an
/// understaffed shift that requires the family's awareness.
@immutable
class FamilyAttentionAlert {
  final String id;
  final String title;
  final String subtitle;
  final AlertSeverity severity;

  const FamilyAttentionAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
  });
}
