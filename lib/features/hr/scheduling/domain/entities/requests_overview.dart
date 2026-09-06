import 'package:flutter/foundation.dart';

import 'open_position.dart';
import 'shift_request.dart';

/// Aggregate for everything shown on the Requests tab.
@immutable
class RequestsOverview {
  final List<ShiftRequest> pendingRequests;
  final List<ShiftRequest> approvedRequests;
  final List<ShiftRequest> declinedRequests;
  final List<OpenPosition> openShiftRequests;

  const RequestsOverview({
    required this.pendingRequests,
    required this.approvedRequests,
    required this.declinedRequests,
    required this.openShiftRequests,
  });
}
