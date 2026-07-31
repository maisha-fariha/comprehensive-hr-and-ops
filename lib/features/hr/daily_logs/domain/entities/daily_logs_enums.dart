/// Which segmented tab is currently selected on the "Daily Logs" screen.
enum DailyLogsTab { review, missing, handover }

/// Semantic tag driving the icon/color of a summary stat tile. Shared across
/// all three Daily Logs tabs (Review / Missing / Handover) since every tab
/// renders the same "3 stat tiles" pattern at the top.
enum DailyLogStatTag {
  submittedToday,
  pendingReview,
  flaggedNotes,
  missingLogs,
  overdue,
  followUpRequired,
  activeHandovers,
  pendingAcknowledgement,
  urgentNotes,
}

/// Review-tab status of a single submitted daily log.
enum LogReviewStatus { complete, inReview, flagged }

/// Category of a single bullet inside a handover entry's "Important Notes".
enum HandoverNoteType { medication, observation, task }
