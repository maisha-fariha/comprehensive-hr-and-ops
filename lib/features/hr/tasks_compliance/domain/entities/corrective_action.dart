import 'package:flutter/foundation.dart';

import 'assignee.dart';
import 'tasks_compliance_enums.dart';

/// A single card in the "Active Corrective Actions" list on the
/// "Corrective" tab.
@immutable
class CorrectiveAction {
  final String id;
  final CorrectiveIssueType issueType;
  final String title;
  final CorrectiveSeverity severity;
  final String locationCategory;
  final String locationName;
  final Assignee assignee;
  final String dueDateLabel;

  /// Whether [dueDateLabel] should be rendered in the "late" (red) color,
  /// e.g. "May 11 · 2d late" vs. a plain future date like "May 20".
  final bool isDueLate;
  final CorrectiveActionStatus status;

  const CorrectiveAction({
    required this.id,
    required this.issueType,
    required this.title,
    required this.severity,
    required this.locationCategory,
    required this.locationName,
    required this.assignee,
    required this.dueDateLabel,
    required this.isDueLate,
    required this.status,
  });
}
