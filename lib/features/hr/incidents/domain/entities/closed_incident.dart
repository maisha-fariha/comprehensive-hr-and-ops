import 'package:flutter/foundation.dart';

import 'incidents_enums.dart';

/// A single row in the "Resolved Incidents" list on the Closed tab. Covers
/// both terminal states Figma shows in this tab: a fully reviewed
/// "Resolved" incident (with a reviewer) and an "Archived" one (no reviewer
/// shown in the source screenshot).
@immutable
class ClosedIncident {
  final String id;
  final String title;
  final IncidentIconKind iconKind;
  final bool isArchived;
  final String subtitle;
  final String dateLabel;
  final String? reviewerInitials;
  final String? reviewerName;

  const ClosedIncident({
    required this.id,
    required this.title,
    required this.iconKind,
    required this.isArchived,
    required this.subtitle,
    required this.dateLabel,
    this.reviewerInitials,
    this.reviewerName,
  });
}
