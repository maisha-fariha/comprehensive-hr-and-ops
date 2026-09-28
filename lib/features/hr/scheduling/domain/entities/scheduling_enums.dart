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
enum RequestStatus { pending, approved, declined }

/// Shift lifecycle filter on the Scheduling "Filters" sheet. [apiValues]
/// lists every raw `status` the API may return for that bucket.
enum ShiftStatusFilter {
  draft('Draft', {'draft'}),
  scheduled('Scheduled', {'scheduled'}),
  published('Published', {'published', 'confirmed'}),
  openForBids('Open for bids', {'open', 'bid_pending', 'bidding'}),
  filled('Filled', {'filled', 'assigned'}),
  completed('Completed', {'completed'}),
  cancelled('Cancelled', {'cancelled', 'canceled'});

  final String label;
  final Set<String> apiValues;

  const ShiftStatusFilter(this.label, this.apiValues);
}
