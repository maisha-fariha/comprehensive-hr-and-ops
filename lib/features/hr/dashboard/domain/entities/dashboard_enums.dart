/// Severity of an item in the "Needs Attention" list.
enum AlertSeverity { critical, urgent }

/// Semantic status tag shown on a "Today's Overview" stat card
/// (drives both the badge label and its color grouping).
enum StatTag { active, urgent, due, review, today, flagged }

/// Which shift block a `ScheduleShift` represents.
enum ShiftPeriod { morning, evening, night }

/// Which quick-action tile is being rendered.
enum QuickActionType { createShift, approve, logNote, message }
