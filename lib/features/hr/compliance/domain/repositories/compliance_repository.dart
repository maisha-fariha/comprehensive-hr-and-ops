import 'package:gems_core/gems_core.dart';

import '../entities/compliance.dart';

abstract class ComplianceRepository {
  Future<Result<ComplianceOverview>> overview();

  Future<Result<List<ComplianceAlert>>> alerts();

  Future<Result<CompliancePageResult<ComplianceRequirement>>> requirements({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  });

  Future<Result<ComplianceRequirement>> createRequirement(
    Map<String, dynamic> body,
  );

  Future<Result<ComplianceRequirement>> archiveRequirement(String id);

  Future<Result<ComplianceRequirement>> restoreRequirement(String id);

  Future<Result<CompliancePageResult<ComplianceCheck>>> checks({
    int page = 1,
    int limit = 20,
    String? filter,
  });

  Future<Result<ComplianceCheck>> createCheck(Map<String, dynamic> body);

  Future<Result<ComplianceCheck>> submitCheck(
    String id,
    Map<String, dynamic> body,
  );

  Future<Result<ComplianceCheck>> reviewCheck(
    String id, {
    Map<String, dynamic> body = const {},
  });

  Future<Result<CompliancePageResult<ComplianceFinding>>> findings({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? severity,
    String? source,
  });

  Future<Result<ComplianceFinding>> createFinding(Map<String, dynamic> body);

  Future<Result<ComplianceFinding>> updateFinding(
    String id,
    Map<String, dynamic> body,
  );

  Future<Result<CompliancePageResult<ComplianceAction>>> actions({
    int page = 1,
    int limit = 20,
    bool overdueOnly = false,
  });

  Future<Result<ComplianceAction>> createAction(Map<String, dynamic> body);

  Future<Result<ComplianceAction>> verifyAction(String id);

  Future<Result<CompliancePageResult<ComplianceAuditLog>>> auditLogs({
    int page = 1,
    int limit = 20,
    String? module,
  });

  Future<Result<ComplianceExportJob>> exportFindingsCsv();

  Future<Result<List<ComplianceExportJob>>> listExports();

  Future<Result<List<CompliancePersonOption>>> residences();

  Future<Result<List<CompliancePersonOption>>> clients({String? residenceId});

  Future<Result<List<CompliancePersonOption>>> staff();
}
