import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/compliance.dart';
import '../../domain/repositories/compliance_repository.dart';
import '../compliance_endpoints.dart';
import '../mappers/compliance_mapper.dart';

class ComplianceRepositoryImpl implements ComplianceRepository {
  final AppApiClient _api;

  ComplianceRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<ComplianceOverview>> overview() async {
    final result = await _api.get(ComplianceEndpoints.overview, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(ComplianceMapper.overviewFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<List<ComplianceAlert>>> alerts() async {
    final result = await _api.get(ComplianceEndpoints.alerts, silent: true);
    return result.when(
      success: (body) async =>
          Result.success(ComplianceMapper.alertsFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<CompliancePageResult<ComplianceRequirement>>> requirements({
    int page = 1,
    int limit = 50,
    bool includeArchived = false,
  }) async {
    final q = StringBuffer(
      '?page=$page&limit=$limit',
    );
    if (includeArchived) q.write('&includeArchived=true');
    final result = await _api.get(
      '${ComplianceEndpoints.requirements}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.pageFrom(
          body,
          ComplianceMapper.requirementsFrom,
          fallbackPage: page,
          fallbackLimit: limit,
        ),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceRequirement>> createRequirement(
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(
      ComplianceEndpoints.requirements,
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.requirementsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not create requirement'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceRequirement>> archiveRequirement(String id) async {
    final result = await _api.post(
      ComplianceEndpoints.archiveRequirement(id),
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.requirementsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not archive requirement'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceRequirement>> restoreRequirement(String id) async {
    final result = await _api.post(
      ComplianceEndpoints.restoreRequirement(id),
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.requirementsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not restore requirement'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<CompliancePageResult<ComplianceCheck>>> checks({
    int page = 1,
    int limit = 20,
    String? filter,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    switch (filter) {
      case 'outstanding':
        q.write('&outstanding=true');
      case 'overdue':
        q.write('&overdue=true');
    }
    final result = await _api.get(
      '${ComplianceEndpoints.checks}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.pageFrom(
          body,
          ComplianceMapper.checksFrom,
          fallbackPage: page,
          fallbackLimit: limit,
        ),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceCheck>> createCheck(Map<String, dynamic> body) async {
    final result = await _api.post(
      ComplianceEndpoints.checks,
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.checksFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not raise check'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceCheck>> submitCheck(
    String id,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(
      ComplianceEndpoints.submitCheck(id),
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.checksFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not record check'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceCheck>> reviewCheck(
    String id, {
    Map<String, dynamic> body = const {},
  }) async {
    final result = await _api.post(
      ComplianceEndpoints.reviewCheck(id),
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.checksFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not sign off check'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<CompliancePageResult<ComplianceFinding>>> findings({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? severity,
    String? source,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    if (search != null && search.trim().isNotEmpty) {
      q.write('&search=${Uri.encodeQueryComponent(search.trim())}');
    }
    if (status != null && status.isNotEmpty) q.write('&status=$status');
    if (severity != null && severity.isNotEmpty) {
      q.write('&severity=$severity');
    }
    if (source != null && source.isNotEmpty) q.write('&source=$source');
    final result = await _api.get(
      '${ComplianceEndpoints.findings}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.pageFrom(
          body,
          ComplianceMapper.findingsFrom,
          fallbackPage: page,
          fallbackLimit: limit,
        ),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceFinding>> createFinding(
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(
      ComplianceEndpoints.findings,
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.findingsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not raise finding'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceFinding>> updateFinding(
    String id,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.patch(
      ComplianceEndpoints.finding(id),
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.findingsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not update finding'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<CompliancePageResult<ComplianceAction>>> actions({
    int page = 1,
    int limit = 20,
    bool overdueOnly = false,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    if (overdueOnly) q.write('&overdue=true');
    final result = await _api.get(
      '${ComplianceEndpoints.correctiveActions}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.pageFrom(
          body,
          ComplianceMapper.actionsFrom,
          fallbackPage: page,
          fallbackLimit: limit,
        ),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceAction>> createAction(
    Map<String, dynamic> body,
  ) async {
    final result = await _api.post(
      ComplianceEndpoints.correctiveActions,
      data: body,
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.actionsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not create action'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceAction>> verifyAction(String id) async {
    final result = await _api.post(
      ComplianceEndpoints.verifyAction(id),
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final list = ComplianceMapper.actionsFrom({
          'data': [JsonCodec.unwrap(body)],
        });
        if (list.isEmpty) {
          return Result.failure(
            const ApiError(message: 'Could not verify action'),
          );
        }
        return Result.success(list.first);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<CompliancePageResult<ComplianceAuditLog>>> auditLogs({
    int page = 1,
    int limit = 20,
    String? module,
  }) async {
    final q = StringBuffer('?page=$page&limit=$limit');
    if (module != null && module.isNotEmpty) q.write('&module=$module');
    final result = await _api.get(
      '${ComplianceEndpoints.auditLogs}$q',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.pageFrom(
          body,
          ComplianceMapper.auditLogsFrom,
          fallbackPage: page,
          fallbackLimit: limit,
        ),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<ComplianceExportJob>> exportFindingsCsv() async {
    final result = await _api.post(
      ComplianceEndpoints.reportsExports,
      data: {
        'reportKey': 'compliance_findings',
        'format': 'csv',
        'filters': <String, dynamic>{},
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async {
        final job = ComplianceMapper.exportFrom(body);
        if (job == null) {
          return Result.failure(const ApiError(message: 'Export failed'));
        }
        return Result.success(job);
      },
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<List<ComplianceExportJob>>> listExports() async {
    final result = await _api.get(
      '${ComplianceEndpoints.reportsExports}?page=1&limit=10',
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        ComplianceMapper.exportsFrom(body)
            .where((j) => j.reportKey.contains('compliance'))
            .toList(),
      ),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<List<CompliancePersonOption>>> residences() async {
    final result = await _api.get(
      '${ComplianceEndpoints.residences}?page=1&limit=100',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(ComplianceMapper.peopleFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<List<CompliancePersonOption>>> clients({
    String? residenceId,
  }) async {
    final q = StringBuffer('?page=1&limit=100');
    if (residenceId != null && residenceId.isNotEmpty) {
      q.write('&residenceId=$residenceId');
    }
    final result = await _api.get(
      '${ComplianceEndpoints.clients}$q',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(ComplianceMapper.peopleFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }

  @override
  Future<Result<List<CompliancePersonOption>>> staff() async {
    final result = await _api.get(
      '${ComplianceEndpoints.staff}?page=1&limit=100',
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(ComplianceMapper.peopleFrom(body)),
      failure: (e) async => Result.failure(e),
    );
  }
}
