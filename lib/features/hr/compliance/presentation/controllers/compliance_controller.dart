import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../data/mappers/compliance_mapper.dart';
import '../../domain/entities/compliance.dart';
import '../../domain/repositories/compliance_repository.dart';

enum ComplianceTab {
  overview,
  requirements,
  checks,
  findings,
  actions,
  alerts,
  audit,
}

/// Web `/dashboard/compliance` state.
class ComplianceController extends GetxController {
  static const pageSizes = ComplianceMapper.pageSizes;

  final ComplianceRepository repository;
  final UserSession session;

  ComplianceController({required this.repository, required this.session});

  final isLoading = false.obs;
  final busy = false.obs;
  final loadError = RxnString();

  final overview = Rxn<ComplianceOverview>();
  final alerts = <ComplianceAlert>[].obs;

  final requirements = <ComplianceRequirement>[].obs;
  final showArchivedRequirements = false.obs;
  final requirementsPage = 1.obs;
  final requirementsLimit = 50.obs;
  final requirementsTotal = 0.obs;
  final requirementsTotalPages = 1.obs;

  final checks = <ComplianceCheck>[].obs;
  final checkFilter = 'all'.obs; // all | outstanding | overdue
  final checksPage = 1.obs;
  final checksLimit = 20.obs;
  final checksTotal = 0.obs;
  final checksTotalPages = 1.obs;
  final checksSummary = <String, dynamic>{}.obs;

  final findings = <ComplianceFinding>[].obs;
  final findingsSearch = ''.obs;
  final findingsStatus = ''.obs;
  final findingsSeverity = ''.obs;
  final findingsSource = ''.obs;
  final findingsPage = 1.obs;
  final findingsLimit = 20.obs;
  final findingsTotal = 0.obs;
  final findingsTotalPages = 1.obs;

  final actions = <ComplianceAction>[].obs;
  final actionsOverdueOnly = false.obs;
  final actionsPage = 1.obs;
  final actionsLimit = 20.obs;
  final actionsTotal = 0.obs;
  final actionsTotalPages = 1.obs;

  final auditLogs = <ComplianceAuditLog>[].obs;
  final auditPage = 1.obs;
  final auditLimit = 20.obs;
  final auditTotal = 0.obs;
  final auditTotalPages = 1.obs;

  final exports = <ComplianceExportJob>[].obs;
  final residences = <CompliancePersonOption>[].obs;
  final clients = <CompliancePersonOption>[].obs;
  final staffOptions = <CompliancePersonOption>[].obs;

  bool get canRead => session.can('compliance:read');
  bool get canWrite => session.can('compliance:write');
  bool get canExport => session.can('compliance:export');
  bool get canUploadDocs => session.can('documents:write');

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    if (!canRead) return;
    isLoading.value = true;
    loadError.value = null;
    await Future.wait([
      _loadOverview(),
      _loadAlerts(),
      _loadRequirements(),
      _loadChecks(),
      _loadFindings(),
      _loadActions(),
      _loadAudit(),
      _loadExports(),
      _loadOptions(),
    ]);
    isLoading.value = false;
  }

  Future<void> _loadOverview() async {
    final result = await repository.overview();
    result.when(
      success: (v) => overview.value = v,
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadAlerts() async {
    final result = await repository.alerts();
    result.when(
      success: alerts.assignAll,
      failure: (_) {},
    );
  }

  Future<void> _loadRequirements() async {
    final result = await repository.requirements(
      page: requirementsPage.value,
      limit: requirementsLimit.value,
      includeArchived: showArchivedRequirements.value,
    );
    result.when(
      success: (page) {
        requirements.assignAll(page.items);
        requirementsTotal.value = page.total;
        requirementsTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadChecks() async {
    final filter =
        checkFilter.value == 'all' ? null : checkFilter.value;
    final result = await repository.checks(
      page: checksPage.value,
      limit: checksLimit.value,
      filter: filter,
    );
    result.when(
      success: (page) {
        checks.assignAll(page.items);
        checksTotal.value = page.total;
        checksTotalPages.value = page.totalPages;
        checksSummary.assignAll(page.summary);
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadFindings() async {
    final result = await repository.findings(
      page: findingsPage.value,
      limit: findingsLimit.value,
      search: findingsSearch.value,
      status: findingsStatus.value,
      severity: findingsSeverity.value,
      source: findingsSource.value,
    );
    result.when(
      success: (page) {
        findings.assignAll(page.items);
        findingsTotal.value = page.total;
        findingsTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadActions() async {
    final result = await repository.actions(
      page: actionsPage.value,
      limit: actionsLimit.value,
      overdueOnly: actionsOverdueOnly.value,
    );
    result.when(
      success: (page) {
        actions.assignAll(page.items);
        actionsTotal.value = page.total;
        actionsTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadAudit() async {
    final result = await repository.auditLogs(
      page: auditPage.value,
      limit: auditLimit.value,
    );
    result.when(
      success: (page) {
        auditLogs.assignAll(page.items);
        auditTotal.value = page.total;
        auditTotalPages.value = page.totalPages;
      },
      failure: (_) {},
    );
  }

  Future<void> _loadExports() async {
    final result = await repository.listExports();
    result.when(success: exports.assignAll, failure: (_) {});
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      repository.residences(),
      repository.staff(),
    ]);
    results[0].when(success: residences.assignAll, failure: (_) {});
    results[1].when(success: staffOptions.assignAll, failure: (_) {});
  }

  Future<void> loadClientsForResidence(String? residenceId) async {
    final result = await repository.clients(residenceId: residenceId);
    result.when(success: clients.assignAll, failure: (_) => clients.clear());
  }

  Future<void> loadRequirements() => _loadRequirements();
  Future<void> loadChecks() => _loadChecks();
  Future<void> loadFindings() => _loadFindings();
  Future<void> loadActions() => _loadActions();
  Future<void> loadAlerts() => _loadAlerts();
  Future<void> loadAuditLogs() => _loadAudit();

  Future<void> setShowArchived(bool value) async {
    showArchivedRequirements.value = value;
    requirementsPage.value = 1;
    await _loadRequirements();
  }

  Future<void> setCheckFilter(String value) async {
    checkFilter.value = value;
    checksPage.value = 1;
    await _loadChecks();
  }

  Future<void> clearFindingsFilters() async {
    findingsSearch.value = '';
    findingsStatus.value = '';
    findingsSeverity.value = '';
    findingsSource.value = '';
    findingsPage.value = 1;
    await _loadFindings();
  }

  Future<void> applyFindingsFilters({
    String? search,
    String? status,
    String? severity,
    String? source,
  }) async {
    if (search != null) findingsSearch.value = search;
    if (status != null) findingsStatus.value = status;
    if (severity != null) findingsSeverity.value = severity;
    if (source != null) findingsSource.value = source;
    findingsPage.value = 1;
    await _loadFindings();
  }

  Future<void> setActionsOverdueOnly(bool value) async {
    actionsOverdueOnly.value = value;
    actionsPage.value = 1;
    await _loadActions();
  }

  Future<void> setRequirementsPage(int page) async {
    requirementsPage.value = page;
    await _loadRequirements();
  }

  Future<void> setRequirementsLimit(int limit) async {
    requirementsLimit.value = limit;
    requirementsPage.value = 1;
    await _loadRequirements();
  }

  Future<void> setChecksPage(int page) async {
    checksPage.value = page;
    await _loadChecks();
  }

  Future<void> setChecksLimit(int limit) async {
    checksLimit.value = limit;
    checksPage.value = 1;
    await _loadChecks();
  }

  Future<void> setFindingsPage(int page) async {
    findingsPage.value = page;
    await _loadFindings();
  }

  Future<void> setFindingsLimit(int limit) async {
    findingsLimit.value = limit;
    findingsPage.value = 1;
    await _loadFindings();
  }

  Future<void> setActionsPage(int page) async {
    actionsPage.value = page;
    await _loadActions();
  }

  Future<void> setActionsLimit(int limit) async {
    actionsLimit.value = limit;
    actionsPage.value = 1;
    await _loadActions();
  }

  Future<void> setAuditPage(int page) async {
    auditPage.value = page;
    await _loadAudit();
  }

  Future<void> setAuditLimit(int limit) async {
    auditLimit.value = limit;
    auditPage.value = 1;
    await _loadAudit();
  }

  Future<String?> createRequirement(Map<String, dynamic> body) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.createRequirement(body);
    String? error;
    await result.when(
      success: (_) async {
        requirementsPage.value = 1;
        await _loadRequirements();
      },
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> archiveRequirement(String id) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.archiveRequirement(id);
    String? error;
    await result.when(
      success: (_) async => _loadRequirements(),
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> restoreRequirement(String id) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.restoreRequirement(id);
    String? error;
    await result.when(
      success: (_) async => _loadRequirements(),
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> raiseCheck(Map<String, dynamic> body) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.createCheck(body);
    String? error;
    await result.when(
      success: (_) async {
        checksPage.value = 1;
        await Future.wait([_loadChecks(), _loadOverview()]);
      },
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> raiseFinding(Map<String, dynamic> body) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.createFinding(body);
    String? error;
    await result.when(
      success: (_) async {
        findingsPage.value = 1;
        await Future.wait([_loadFindings(), _loadOverview(), _loadAlerts()]);
      },
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> createAction(Map<String, dynamic> body) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.createAction(body);
    String? error;
    await result.when(
      success: (_) async {
        actionsPage.value = 1;
        await Future.wait([_loadActions(), _loadOverview()]);
      },
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> verifyAction(String id) async {
    if (!canWrite) return 'You need compliance write access.';
    busy.value = true;
    final result = await repository.verifyAction(id);
    String? error;
    await result.when(
      success: (_) async => _loadActions(),
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }

  Future<String?> exportReport() async {
    if (!canExport) return 'You need compliance export access.';
    busy.value = true;
    final result = await repository.exportFindingsCsv();
    String? error;
    await result.when(
      success: (job) async {
        exports.insert(0, job);
      },
      failure: (e) async => error = e.message,
    );
    busy.value = false;
    return error;
  }
}
