import 'package:flutter/foundation.dart';

import 'scheduling_enums.dart';

/// A single row in the Board tab's "Open Positions" list, e.g.
/// "RN Needed — Morning Shift · Pinecrest Manor".
@immutable
class OpenPosition {
  final String id;
  final String roleTitle;
  final OpenPositionUrgency urgency;
  final String subtitle;

  const OpenPosition({
    required this.id,
    required this.roleTitle,
    required this.urgency,
    required this.subtitle,
  });
}
