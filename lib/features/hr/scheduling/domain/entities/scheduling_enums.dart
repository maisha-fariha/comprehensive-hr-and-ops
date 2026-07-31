/// Which of the 3 segmented tabs is currently selected on the Scheduling
/// screen.
enum SchedulingTab { calendar, board, requests }

/// Coverage/staffing health for a shift, drives the color of its ratio
/// badge, progress bar and status label everywhere it appears (Calendar
/// shift cards, Board coverage tiles and coverage-board cards).
enum CoverageStatus { almostFull, needsAttention }

/// Urgency of an unfilled role in the "Open Positions" list on the Board
/// tab.
enum OpenPositionUrgency { urgent, open }

/// Lifecycle state of a shift-swap request on the Requests tab.
enum RequestStatus { pending, approved }
