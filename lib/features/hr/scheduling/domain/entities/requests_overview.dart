import 'package:flutter/foundation.dart';

import 'shift_request.dart';

/// Aggregate for everything shown on the Requests tab.
@immutable
class RequestsOverview {
  final List<ShiftRequest> pendingRequests;
  final List<ShiftRequest> approvedRequests;

  const RequestsOverview({
    required this.pendingRequests,
    required this.approvedRequests,
  });
}
