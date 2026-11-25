import 'package:gems_core/gems_core.dart';

import '../entities/ai_report.dart';

abstract interface class AiAlertsRepository {
  Future<Result<AiFeatureGate>> getFeatureGate();

  Future<Result<AiReportsPage>> getReports({
    int page,
    int limit,
    String? q,
    String? kind,
    String? severity,
    String? residenceId,
    String? from,
    String? to,
    bool unreadOnly,
  });

  Future<Result<AiReportDetail>> getReportDetail(String id);

  Future<Result<AiReportAutomationsPage>> getAutomations();
}
