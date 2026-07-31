import 'package:flutter/foundation.dart';

import 'family_daily_update_entry.dart';

/// Aggregate root for everything shown on the Family "Daily Updates" screen.
@immutable
class FamilyDailyUpdatesOverview {
  final String screenTitle;
  final String screenSubtitle;
  final String dateSectionLabel;
  final List<FamilyDailyUpdateEntry> entries;
  final String footerNote;

  const FamilyDailyUpdatesOverview({
    required this.screenTitle,
    required this.screenSubtitle,
    required this.dateSectionLabel,
    required this.entries,
    required this.footerNote,
  });
}
