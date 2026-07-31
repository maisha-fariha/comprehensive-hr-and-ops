/// Which segment of the "Tasks & Compliance" screen's top segmented tab bar
/// is currently selected.
enum TasksComplianceTab { tasks, compliance, corrective }

/// Semantic tag for a tile in the "Tasks" tab's 2x2 stat grid.
enum TaskStatTag { dueToday, thisWeek, upcoming, completed }

/// Which category a task belongs to; drives both the list tile's icon and
/// the small category tag chip shown under the task title.
enum TaskCategory { safety, facilities, medication, audit }

/// Trailing status pill shown on a task list tile.
enum TaskStatus { overdue, due, upcoming }

/// Semantic tag for a tile in the "Compliance" tab's 3-column stat row.
enum ComplianceStatTag { completed, pendingReview, needsAttention }

/// Status of a single compliance checklist item; drives both its leading
/// icon and its trailing status pill.
enum ComplianceItemStatus { completed, pending, dueSoon }

/// Semantic tag for a tile in the "Corrective" tab's 2x2 stat grid.
enum CorrectiveStatTag { open, inProgress, completed, overdue }

/// The nature of the underlying issue a corrective action addresses; drives
/// the card's leading icon.
enum CorrectiveIssueType { documentationError, safetyImprovement, handoverGap }

/// Priority pill shown on a corrective action card.
enum CorrectiveSeverity { high, medium }

/// Current progress of a corrective action; drives the footer status dot.
enum CorrectiveActionStatus { overdue, inProgress }
