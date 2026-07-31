import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';

/// A single card shown on the "My Requests" tab of the Visit Requests list
/// screen - fuller than the "All"/"History" tabs' rows, with a leading
/// colored status dot next to the date, a description/notes line, and a
/// "View Request Details" link that pushes [VisitRequestDetail] for [id].
@immutable
class MyVisitRequest {
  final String id;
  final VisitRequestType type;
  final String dateTimeLabel;
  final VisitRequestStatus status;
  final String description;

  const MyVisitRequest({
    required this.id,
    required this.type,
    required this.dateTimeLabel,
    required this.status,
    required this.description,
  });
}
