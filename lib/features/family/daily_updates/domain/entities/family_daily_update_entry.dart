import 'package:flutter/foundation.dart';

import 'family_daily_update_enums.dart';

/// A single row in the "Daily Updates" vertical timeline, e.g. the 8:00 AM
/// "Mood" entry.
@immutable
class FamilyDailyUpdateEntry {
  final String id;
  final DailyUpdateCategory category;
  final String timeLabel;
  final String title;
  final String description;
  final bool hasPhoto;

  /// Whether the connecting timeline divider should render below this row
  /// (true for every row except the last).
  final bool showTimelineDivider;

  const FamilyDailyUpdateEntry({
    required this.id,
    required this.category,
    required this.timeLabel,
    required this.title,
    required this.description,
    this.hasPhoto = false,
    this.showTimelineDivider = true,
  });
}
