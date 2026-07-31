import 'package:flutter/foundation.dart';

import 'dashboard_enums.dart';

/// A single tile in the "Quick Actions" row, e.g. "Create Shift" or
/// "Approve".
@immutable
class QuickAction {
  final QuickActionType type;
  final String label;

  const QuickAction({required this.type, required this.label});
}
