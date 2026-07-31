import 'package:flutter/foundation.dart';

import 'staff_daily_logs_enums.dart';

/// A single dropdown-style row on the "Daily Note" screen, e.g.
/// "Mood → Happy".
@immutable
class DailyNoteField {
  final DailyNoteFieldKey key;
  final String label;
  final String value;

  const DailyNoteField({
    required this.key,
    required this.label,
    required this.value,
  });
}
