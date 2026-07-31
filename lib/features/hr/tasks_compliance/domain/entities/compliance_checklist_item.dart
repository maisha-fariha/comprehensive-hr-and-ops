import 'package:flutter/foundation.dart';

import 'assignee.dart';
import 'tasks_compliance_enums.dart';

/// A single row in the "Compliance Checklist" list on the "Compliance" tab.
@immutable
class ComplianceChecklistItem {
  final String id;
  final String title;
  final String category;
  final Assignee assignee;
  final String dateLabel;
  final ComplianceItemStatus status;

  const ComplianceChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    required this.assignee,
    required this.dateLabel,
    required this.status,
  });
}
