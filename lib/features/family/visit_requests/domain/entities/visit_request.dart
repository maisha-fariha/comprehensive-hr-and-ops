import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';

/// A single row shown on the "All" and "History" tabs of the Visit
/// Requests list screen.
///
/// [mode]/[locationLabel] are only populated for the "All" tab's rows,
/// which show a location-or-telehealth line under the type tag - the
/// "History" tab's rows omit that line entirely per the Figma screenshot,
/// so both are left `null` for history items.
@immutable
class VisitRequest {
  final String id;
  final String requesterName;
  final VisitRequestType type;
  final VisitRequestMode? mode;
  final String? locationLabel;
  final String dateTimeLabel;
  final VisitRequestStatus status;

  const VisitRequest({
    required this.id,
    required this.requesterName,
    required this.type,
    this.mode,
    this.locationLabel,
    required this.dateTimeLabel,
    required this.status,
  });
}
