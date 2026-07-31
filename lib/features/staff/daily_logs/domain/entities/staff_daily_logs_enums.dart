/// Which segmented tab is currently selected on the Staff "Daily Logs"
/// screen.
enum StaffDailyLogsTab { myClients, inProgress, submitted }

/// Semantic tag driving the icon/color of a summary stat tile. The same 3
/// stat tiles are shown at the top of every tab per the reference
/// screenshots.
enum StaffDailyLogStatTag { submittedToday, pendingReview, flaggedNotes }

/// Status of a single client's daily log, driving the trailing pill color
/// on every client row/card across all 3 tabs.
enum ClientLogStatus { pending, inProgress, submitted }

/// Identifies a single form row on the "Daily Note" screen, driving its
/// icon/color and its position in the list.
enum DailyNoteFieldKey { mood, meals, sleep, hygiene, activities, behavior, wellness }
