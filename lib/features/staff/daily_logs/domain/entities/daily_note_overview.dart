import 'package:flutter/foundation.dart';

import 'daily_note_field.dart';

/// Aggregate root for the "Daily Note" screen's fetched content: the
/// vertical list of "How is {name} today?" form fields.
@immutable
class DailyNoteOverview {
  final List<DailyNoteField> fields;

  const DailyNoteOverview({required this.fields});
}
