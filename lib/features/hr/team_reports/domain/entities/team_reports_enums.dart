/// Which segment of the "Team & Reports" segmented tab bar is selected.
enum TeamReportsTab { team, reports, messages }

/// Which stat tile is being rendered in the "Team" tab's 2x2 overview grid.
enum TeamStatTag { totalStaff, onDutyNow, openShifts, vacancies }

/// Which stat tile is being rendered in the "Reports" tab's 2x2 overview
/// grid.
enum ReportStatTag { generated, pendingReview, critical, scheduled }

/// Which stat tile is being rendered in the "Messages" tab's overview row.
enum MessageStatTag { unread, urgent }

/// Which report "type" an entry represents. Shared between the Team tab's
/// "Top Reports" rows and the Reports tab's "Available Reports" cards so
/// both use identical icon/color styling for the same report type.
enum ReportTypeTag { dailyCensus, incidentAnalysis, medicationCompliance, staffAttendance }

/// Which announcement is being rendered in the Messages tab's "Important
/// Announcements" list.
enum AnnouncementTag { policy, training }

/// Urgency pill shown on an announcement card.
enum AnnouncementPriority { highPriority, upcoming }
