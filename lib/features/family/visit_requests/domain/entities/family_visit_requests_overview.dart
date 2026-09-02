import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';
import 'my_visit_request.dart';
import 'visit_request.dart';

/// Aggregate root for everything shown on the Visit Requests list screen -
/// one list per tab, fetched together so the screen has a single loading/
/// error state (mirroring `DashboardOverview` in the HR dashboard feature).
@immutable
class FamilyVisitRequestsOverview {
  final List<VisitRequest> allRequests;
  final List<MyVisitRequest> myRequests;
  final List<VisitRequest> historyRequests;

  const FamilyVisitRequestsOverview({
    required this.allRequests,
    required this.myRequests,
    required this.historyRequests,
  });

  int get pendingCount =>
      myRequests.where((request) => request.status == VisitRequestStatus.pending).length;
  int get approvedCount =>
      myRequests.where((request) => request.status == VisitRequestStatus.approved).length;
  int get rejectedCount => historyRequests
      .where((request) => request.status == VisitRequestStatus.rejected)
      .length;
}
