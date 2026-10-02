import 'package:flutter/foundation.dart';

import 'family_visit_requests_enums.dart';
import 'my_visit_request.dart';

/// Every family visit request of the signed-in family member, with per-tab
/// filtering and counts derived from the same list so a tab's count always
/// equals the number of cards it shows.
@immutable
class FamilyVisitRequestsOverview {
  final List<MyVisitRequest> requests;

  const FamilyVisitRequestsOverview({required this.requests});

  static VisitRequestStatus? statusOf(FamilyVisitRequestsTab tab) {
    switch (tab) {
      case FamilyVisitRequestsTab.all:
        return null;
      case FamilyVisitRequestsTab.pending:
        return VisitRequestStatus.pending;
      case FamilyVisitRequestsTab.approved:
        return VisitRequestStatus.approved;
      case FamilyVisitRequestsTab.rejected:
        return VisitRequestStatus.rejected;
      case FamilyVisitRequestsTab.cancelled:
        return VisitRequestStatus.cancelled;
      case FamilyVisitRequestsTab.completed:
        return VisitRequestStatus.completed;
    }
  }

  List<MyVisitRequest> requestsFor(FamilyVisitRequestsTab tab) {
    final status = statusOf(tab);
    if (status == null) return requests;
    return requests.where((request) => request.status == status).toList();
  }

  int countFor(FamilyVisitRequestsTab tab) => requestsFor(tab).length;
}
