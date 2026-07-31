import 'package:flutter/foundation.dart';

import 'team_reports_enums.dart';

/// A single card in the Messages tab's "Important Announcements" list.
@immutable
class Announcement {
  final String id;
  final AnnouncementTag tag;
  final String title;
  final String dateLabel;
  final AnnouncementPriority priority;

  const Announcement({
    required this.id,
    required this.tag,
    required this.title,
    required this.dateLabel,
    required this.priority,
  });
}
