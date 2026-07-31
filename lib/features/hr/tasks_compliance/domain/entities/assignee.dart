import 'package:flutter/foundation.dart';

/// Which color variant an [Assignee]'s initials chip is rendered in. Figma
/// assigns a different accent per person purely for visual variety, not for
/// any semantic reason, so this is a plain rotating tag rather than
/// something derived from the person's name/role.
enum AssigneeColorTag { blue, purple, green }

/// A person a task/checklist item/corrective action is assigned to,
/// rendered as a small colored initials chip (e.g. "SJ" for "Sarah J.").
@immutable
class Assignee {
  final String initials;
  final String name;
  final AssigneeColorTag colorTag;

  const Assignee({
    required this.initials,
    required this.name,
    required this.colorTag,
  });
}
