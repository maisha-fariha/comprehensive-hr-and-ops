import 'package:flutter/foundation.dart';

import 'assignee.dart';

/// A row in "Upcoming Compliance Reviews" from `GET /compliance/requirements`.
@immutable
class ComplianceRequirementItem {
  final String id;
  final String title;
  final String frequencyLabel;
  final String category;
  final Assignee supervisor;

  const ComplianceRequirementItem({
    required this.id,
    required this.title,
    required this.frequencyLabel,
    required this.category,
    required this.supervisor,
  });
}
