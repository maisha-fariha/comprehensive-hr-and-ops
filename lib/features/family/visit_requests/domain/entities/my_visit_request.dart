import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';

/// A single card on the "My Requests" tab of Visit Requests.
@immutable
class MyVisitRequest {
  final String id;
  final VisitRequestType type;
  final String dateTimeLabel;
  final VisitRequestStatus status;

  /// Location / mode line under the type tag, e.g. "In-Person at Sunrise Home"
  /// or "Remote / Video Call".
  final String locationModeLabel;

  /// Optional notes shown below a divider. Null / empty hides the notes block.
  final String? notes;

  const MyVisitRequest({
    required this.id,
    required this.type,
    required this.dateTimeLabel,
    required this.status,
    required this.locationModeLabel,
    this.notes,
  });
}
