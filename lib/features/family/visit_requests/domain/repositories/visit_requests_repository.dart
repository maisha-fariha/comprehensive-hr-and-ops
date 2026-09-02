import 'package:gems_core/gems_core.dart';

import '../entities/family_visit_requests_overview.dart';
import '../entities/visit_request_detail.dart';

abstract class VisitRequestsRepository {
  Future<Result<FamilyVisitRequestsOverview>> getOverview();

  Future<Result<VisitRequestDetail>> getRequestDetail(String requestId);

  Future<Result<void>> reschedule({
    required String requestId,
    required DateTime scheduledAt,
  });

  Future<Result<void>> cancel(String requestId);
}
