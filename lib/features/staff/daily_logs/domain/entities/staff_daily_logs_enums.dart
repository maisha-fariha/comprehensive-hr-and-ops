/// Which segmented tab is selected on Staff Daily Logs (web parity).
enum StaffDailyLogsTab { toReview, missing, residentDay, houseActivity }

/// Semantic tag for summary stat tiles (web parity).
enum StaffDailyLogStatTag {
  entriesLogged,
  daysToReview,
  missingLogs,
  openFlags,
  // legacy aliases still referenced in older tiles
  submittedToday,
  pendingReview,
  flaggedNotes,
}

/// Status of a client daily-log row.
enum ClientLogStatus { pending, inProgress, submitted, toReview, missing }

/// Identifies a single form row on the "Daily Note" screen.
enum DailyNoteFieldKey { mood, meals, sleep, hygiene, activities, behavior, wellness }
