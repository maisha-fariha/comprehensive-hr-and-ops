import 'package:flutter/foundation.dart';

import 'family_daily_update_enums.dart';

/// One Care Journal card (web Care Note or Family memory / activity).
@immutable
class FamilyDailyUpdateEntry {
  final String id;
  final DailyUpdateCategory category;
  final String timeLabel;
  final String title;
  final String description;
  final String? authorName;
  final bool hasPhoto;
  final List<String> mediaUrls;

  /// Whether the connecting timeline divider should render below this row
  /// (true for every row except the last).
  final bool showTimelineDivider;

  const FamilyDailyUpdateEntry({
    required this.id,
    required this.category,
    required this.timeLabel,
    required this.title,
    required this.description,
    this.authorName,
    this.hasPhoto = false,
    this.mediaUrls = const [],
    this.showTimelineDivider = true,
  });

  bool get isFamilyMemory =>
      category == DailyUpdateCategory.activities ||
      title.toLowerCase().contains('memory');
}
