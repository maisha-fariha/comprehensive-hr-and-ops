import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';

/// Full read-only content for the Request Details screen, reached by
/// tapping "View Request Details" on a "My Requests" card.
@immutable
class VisitRequestDetail {
  final String id;
  final VisitRequestType type;
  final VisitRequestStatus status;
  final String dateTimeLabel;
  final String locationModeLabel;
  final String patientName;
  final String assignedStaffLabel;
  final String roomLocationLabel;
  final String purpose;
  final String notes;

  const VisitRequestDetail({
    required this.id,
    required this.type,
    required this.status,
    required this.dateTimeLabel,
    required this.locationModeLabel,
    required this.patientName,
    required this.assignedStaffLabel,
    required this.roomLocationLabel,
    required this.purpose,
    required this.notes,
  });

  /// Whether the "Cancel Request" button at the bottom of the details
  /// screen should show - only makes sense while a request hasn't already
  /// been rejected/completed/cancelled.
  bool get isCancellable => status == VisitRequestStatus.pending || status == VisitRequestStatus.approved;
}
