import 'package:gems_core/gems_core.dart';

import '../entities/family_visit_requests_overview.dart';
import '../entities/visit_request_detail.dart';

/// Contract for fetching the Family Visit Requests feature's content. The
/// presentation layer only ever depends on this interface, so swapping the
/// mocked [VisitRequestsRepositoryImpl] for a real API-backed implementation
/// later requires no changes above the data layer.
abstract class VisitRequestsRepository {
  Future<Result<FamilyVisitRequestsOverview>> getOverview();

  Future<Result<VisitRequestDetail>> getRequestDetail(String requestId);
}
