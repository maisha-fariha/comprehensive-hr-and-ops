import 'package:get/get.dart';

import '../../../../../core/roles/user_session.dart';
import '../../data/mappers/finance_mapper.dart';
import '../../domain/entities/finance.dart';
import '../../domain/repositories/finance_repository.dart';

/// Web `/dashboard/finance` state (all tabs except Billing).
class FinanceController extends GetxController {
  static const pageSizes = FinanceLabels.pageSizes;

  final FinanceRepository repository;
  final UserSession session;

  FinanceController({required this.repository, required this.session});

  final isLoading = false.obs;
  final busy = false.obs;
  /// Which mutation owns [busy] so only that control shows Queueing…/Sending….
  final busyAction = RxnString();

  void _beginBusy(String action) {
    busy.value = true;
    busyAction.value = action;
  }

  void _endBusy() {
    busy.value = false;
    busyAction.value = null;
  }
  final loadError = RxnString();

  final runs = <PayrollRun>[].obs;
  final runsPage = 1.obs;
  final runsLimit = 20.obs;
  final runsTotal = 0.obs;
  final runsTotalPages = 1.obs;

  final expenseClaims = <PayrollClaim>[].obs;
  final mileageClaims = <PayrollClaim>[].obs;
  final expensePage = 1.obs;
  final expenseLimit = 20.obs;
  final expenseTotal = 0.obs;
  final expenseTotalPages = 1.obs;
  final mileagePage = 1.obs;
  final mileageLimit = 20.obs;
  final mileageTotal = 0.obs;
  final mileageTotalPages = 1.obs;

  final mileageRates = <MileageRate>[].obs;
  final report = Rxn<FinanceReport>();
  final ledgerEntries = <FinanceLedgerEntry>[].obs;
  final engine = Rxn<PayrollEngine>();
  final overview = Rxn<PayrollOverviewStats>();
  final selectedRun = Rxn<PayrollRun>();
  final overviewSearch = ''.obs;

  final staffOptions = <FinancePersonOption>[].obs;
  final residenceOptions = <FinancePersonOption>[].obs;
  final clientOptions = <FinancePersonOption>[].obs;

  final addons = <BillingAddon>[].obs;
  final selectedAddonKey = 'quickbooks'.obs;
  final quickBooks = Rxn<QuickBooksStatus>();
  final lastPayrollExport = Rxn<FinanceExportJob>();

  final sensitiveStaffId = ''.obs;
  final sensitive = Rxn<StaffSensitiveInfo>();

  final pnlFrom = ''.obs;
  final pnlTo = ''.obs;
  final pnlResidenceId = ''.obs;

  bool get canReadPayroll => session.can('payroll:read');
  bool get canWritePayroll => session.can('payroll:write');
  bool get canReadFinance => session.can('finance:read');
  bool get canWriteFinance => session.can('finance:write');
  bool get canReadPii => session.can('staff:pii:read');
  bool get canWritePii => session.can('staff:pii:write');

  PayrollRun? get activeRun {
    if (runs.isEmpty) return null;
    final sorted = [...runs]..sort((a, b) {
        final aStart = a.periodStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bStart = b.periodStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bStart.compareTo(aStart);
      });
    return sorted.first;
  }

  List<PayrollEntry> get overviewEntries {
    final entries = activeRun?.entries ?? const <PayrollEntry>[];
    final q = overviewSearch.value.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return [
      for (final e in entries)
        if (e.staffName.toLowerCase().contains(q) ||
            e.residenceName.toLowerCase().contains(q))
          e,
    ];
  }

  /// Web overview AreaChart: last 6 runs by `periodStart`, value = gross + adj.
  List<({String label, double value, DateTime? at})> get payrollTrend {
    final dated = [
      for (final run in runs)
        if (run.periodStart != null) run,
    ]..sort((a, b) => a.periodStart!.compareTo(b.periodStart!));
    final last = dated.length > 6 ? dated.sublist(dated.length - 6) : dated;
    return [
      for (final run in last)
        (
          label: FinanceLabels.dayLabel(run.periodStart!),
          value: run.grossTotal,
          at: run.periodStart,
        ),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    pnlFrom.value =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
    pnlTo.value = FinanceLabels.ymd(
      DateTime(now.year, now.month + 1, 0),
    );
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    loadError.value = null;
    final futures = <Future>[];
    if (canReadPayroll) {
      futures.addAll([
        _loadRuns(),
        _loadClaims(),
        _loadEngine(),
        _loadMileageRates(),
        _loadStaff(),
        _loadResidences(),
        _loadExports(),
      ]);
    }
    if (canReadFinance) {
      futures.addAll([_loadReport(), _loadLedger(), _loadClients()]);
    }
    futures.addAll([_loadAddons(), _loadQuickBooks()]);
    await Future.wait(futures);
    if (canReadPii && staffOptions.isNotEmpty && sensitiveStaffId.value.isEmpty) {
      await loadSensitive(staffOptions.first.id);
    }
    _rebuildOverview();
    isLoading.value = false;
  }

  Future<void> _loadRuns() async {
    // Overview trend needs the newest runs; keep page size for the Runs tab
    // but always pull enough rows for the last-6 AreaChart when on page 1.
    final limit = runsPage.value == 1
        ? (runsLimit.value < 20 ? 20 : runsLimit.value)
        : runsLimit.value;
    final result = await repository.listRuns(
      page: runsPage.value,
      limit: limit,
    );
    result.when(
      success: (page) {
        runs.assignAll(page.items);
        runsTotal.value = page.total;
        runsTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadEngine() async {
    final result = await repository.engine();
    result.when(
      success: (value) => engine.value = value,
      failure: (_) {},
    );
  }

  Future<void> _loadClaims() async {
    final expenses = await repository.expenseClaims(
      page: expensePage.value,
      limit: expenseLimit.value,
    );
    final mileage = await repository.mileageClaims(
      page: mileagePage.value,
      limit: mileageLimit.value,
    );
    expenses.when(
      success: (page) {
        expenseClaims.assignAll(page.items);
        expenseTotal.value = page.total;
        expenseTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
    mileage.when(
      success: (page) {
        mileageClaims.assignAll(page.items);
        mileageTotal.value = page.total;
        mileageTotalPages.value = page.totalPages;
      },
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadMileageRates() async {
    final result = await repository.mileageRates();
    result.when(
      success: (items) => mileageRates.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> _loadReport() async {
    final result = await repository.report(
      from: pnlFrom.value,
      to: pnlTo.value,
      residenceId:
          pnlResidenceId.value.isEmpty ? null : pnlResidenceId.value,
    );
    result.when(
      success: (value) => report.value = value,
      failure: (e) => loadError.value ??= e.message,
    );
  }

  Future<void> _loadLedger() async {
    final result = await repository.ledgerEntries(
      from: pnlFrom.value,
      to: pnlTo.value,
      residenceId:
          pnlResidenceId.value.isEmpty ? null : pnlResidenceId.value,
    );
    result.when(
      success: (items) => ledgerEntries.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> _loadStaff() async {
    if (!session.canReadStaffList) {
      staffOptions.clear();
      return;
    }
    final result = await repository.staffOptions();
    result.when(
      success: (items) => staffOptions.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> _loadResidences() async {
    final result = await repository.residenceOptions();
    result.when(
      success: (items) => residenceOptions.assignAll(items),
      failure: (_) {},
    );
  }

  Future<void> _loadClients({String? residenceId}) async {
    final result = await repository.clientOptions(
      residenceId: residenceId ??
          (pnlResidenceId.value.isEmpty ? null : pnlResidenceId.value),
    );
    result.when(
      success: (items) => clientOptions.assignAll(items),
      failure: (_) {},
    );
  }

  Future<List<FinancePersonOption>> clientsForCostAnalysis() async {
    final result = await repository.clientOptions(
      residenceId:
          pnlResidenceId.value.isEmpty ? null : pnlResidenceId.value,
    );
    return result.when(
      success: (items) {
        clientOptions.assignAll(items);
        return items;
      },
      failure: (_) => clientOptions.toList(),
    );
  }

  Future<void> _loadAddons() async {
    final result = await repository.addons();
    result.when(
      success: (items) {
        addons.assignAll(items);
        if (items.isNotEmpty &&
            !items.any((a) => a.key == selectedAddonKey.value)) {
          selectedAddonKey.value = items.first.key;
        }
      },
      failure: (_) {},
    );
  }

  Future<void> _loadQuickBooks() async {
    final result = await repository.quickBooksStatus();
    result.when(
      success: (value) => quickBooks.value = value,
      failure: (_) {},
    );
  }

  Future<void> _loadExports() async {
    final result = await repository.listPayrollExports();
    result.when(
      success: (items) {
        if (items.isNotEmpty) lastPayrollExport.value = items.first;
      },
      failure: (_) {},
    );
  }

  void _rebuildOverview() {
    if (!canReadPayroll) {
      overview.value = null;
      return;
    }
    overview.value = FinanceMapper.overviewFrom(
      runs: runs.toList(),
      expenseClaims: expenseClaims.toList(),
      mileageClaims: mileageClaims.toList(),
      engine: engine.value,
      residentCount: clientOptions.length,
    );
  }

  Future<void> setRunsPage(int page) async {
    runsPage.value = page;
    isLoading.value = true;
    await _loadRuns();
    _rebuildOverview();
    isLoading.value = false;
  }

  Future<void> setRunsLimit(int limit) async {
    runsLimit.value = limit;
    runsPage.value = 1;
    await setRunsPage(1);
  }

  Future<void> setExpensePage(int page) async {
    expensePage.value = page;
    isLoading.value = true;
    await _loadClaims();
    isLoading.value = false;
  }

  Future<void> setExpenseLimit(int limit) async {
    expenseLimit.value = limit;
    expensePage.value = 1;
    await setExpensePage(1);
  }

  Future<void> setMileagePage(int page) async {
    mileagePage.value = page;
    isLoading.value = true;
    await _loadClaims();
    isLoading.value = false;
  }

  Future<void> setMileageLimit(int limit) async {
    mileageLimit.value = limit;
    mileagePage.value = 1;
    await setMileagePage(1);
  }

  Future<void> setPnlRange({
    required String from,
    required String to,
    String? residenceId,
  }) async {
    pnlFrom.value = from;
    pnlTo.value = to;
    if (residenceId != null) pnlResidenceId.value = residenceId;
    isLoading.value = true;
    await Future.wait([
      _loadReport(),
      _loadLedger(),
      if (canReadFinance) _loadClients(),
    ]);
    isLoading.value = false;
  }

  Future<void> openRun(String id) async {
    for (final run in runs) {
      if (run.id == id && run.entries.isNotEmpty) {
        selectedRun.value = run;
        break;
      }
    }
    final result = await repository.getRun(id);
    result.when(
      success: (run) {
        selectedRun.value = run;
        final i = runs.indexWhere((r) => r.id == id);
        if (i >= 0) runs[i] = run;
      },
      failure: (e) => loadError.value = e.message,
    );
  }

  Future<String?> createRun({
    required String periodType,
    required String periodStart,
    required String periodEnd,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('createRun');
    final result = await repository.createRun(
      periodType: periodType,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    String? error;
    await result.when(
      success: (_) async {
        runsPage.value = 1;
        await _loadRuns();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> finalizeRun(String id) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('finalizeRun');
    final result = await repository.finalizeRun(id);
    String? error;
    await result.when(
      success: (run) async {
        selectedRun.value = run;
        await _loadRuns();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> adjustEntry({
    required String entryId,
    required double manualAdjustment,
    String? notes,
    String? adjustmentType,
    String? reason,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('adjustEntry');
    final result = await repository.adjustEntry(
      entryId: entryId,
      manualAdjustment: manualAdjustment,
      notes: notes,
      adjustmentType: adjustmentType,
      reason: reason,
    );
    String? error;
    await result.when(
      success: (_) async {
        final runId = selectedRun.value?.id ?? activeRun?.id;
        if (runId != null) await openRun(runId);
        await _loadRuns();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> decideClaim({
    required PayrollClaim claim,
    required String status,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    final result = claim.kind == 'mileage'
        ? await repository.approveMileageClaim(id: claim.id, status: status)
        : await repository.approveExpenseClaim(id: claim.id, status: status);
    String? error;
    await result.when(
      success: (_) async {
        await _loadClaims();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    return error;
  }

  Future<String?> fileExpenseClaim({
    required String staffId,
    required String residenceId,
    required double amount,
    String? description,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('adjustEntry');
    final result = await repository.createExpenseClaim(
      staffId: staffId,
      residenceId: residenceId,
      amount: amount,
      description: description,
    );
    String? error;
    await result.when(
      success: (_) async {
        expensePage.value = 1;
        await _loadClaims();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> fileMileageClaim({
    required String staffId,
    required String residenceId,
    required double distance,
    required String unit,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('adjustEntry');
    final result = await repository.createMileageClaim(
      staffId: staffId,
      residenceId: residenceId,
      distance: distance,
      unit: unit,
    );
    String? error;
    await result.when(
      success: (_) async {
        mileagePage.value = 1;
        await _loadClaims();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> setMileageRate({
    required String unit,
    required double rateAmount,
    required String effectiveFrom,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('adjustEntry');
    final result = await repository.createMileageRate(
      unit: unit,
      rateAmount: rateAmount,
      effectiveFrom: effectiveFrom,
    );
    String? error;
    await result.when(
      success: (_) async => _loadMileageRates(),
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> endMileageRate(String rateId) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('adjustEntry');
    final result = await repository.endMileageRate(
      rateId: rateId,
      effectiveTo: FinanceLabels.ymd(DateTime.now()),
    );
    String? error;
    await result.when(
      success: (_) async => _loadMileageRates(),
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> createLedgerEntry({
    required String residenceId,
    required String entryType,
    required String category,
    required double amount,
    required String occurredOn,
    String? description,
  }) async {
    if (!canWriteFinance) return 'You need finance write access.';
    _beginBusy('adjustEntry');
    final result = await repository.createLedgerEntry(
      residenceId: residenceId,
      entryType: entryType,
      category: category,
      amount: amount,
      occurredOn: occurredOn,
      description: description,
    );
    String? error;
    await result.when(
      success: (_) async {
        await Future.wait([_loadLedger(), _loadReport()]);
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> deleteLedgerEntry(String id) async {
    if (!canWriteFinance) return 'You need finance write access.';
    _beginBusy('deleteLedgerEntry');
    final result = await repository.deleteLedgerEntry(id);
    String? error;
    await result.when(
      success: (_) async {
        await Future.wait([_loadLedger(), _loadReport()]);
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<ResultOrError<ClientCostSummary>> loadClientCost(String clientId) async {
    final result = await repository.clientCost(
      clientId: clientId,
      from: pnlFrom.value,
      to: pnlTo.value,
    );
    return result.when(
      success: (v) => ResultOrError.value(v),
      failure: (e) => ResultOrError.error(e.message),
    );
  }

  Future<String?> setPayrollEngine({required bool runHere}) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('deleteLedgerEntry');
    final result = await repository.setEngine(runHere: runHere);
    String? error;
    await result.when(
      success: (value) async {
        engine.value = value;
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<ResultOrError<String>> connectQuickBooks() async {
    _beginBusy('deleteLedgerEntry');
    final result = await repository.quickBooksConnectUrl();
    _endBusy();
    return result.when(
      success: (url) => ResultOrError.value(url),
      failure: (e) => ResultOrError.error(e.message),
    );
  }

  Future<void> loadSensitive(String staffId) async {
    if (!canReadPii) return;
    sensitiveStaffId.value = staffId;
    final result = await repository.staffSensitive(staffId);
    result.when(
      success: (value) => sensitive.value = value,
      failure: (e) => loadError.value = e.message,
    );
  }

  Future<String?> revealSensitive() async {
    if (!canReadPii || sensitiveStaffId.value.isEmpty) {
      return 'You need staff PII read access.';
    }
    _beginBusy('revealSensitive');
    final result = await repository.staffSensitive(
      sensitiveStaffId.value,
      reveal: true,
    );
    String? error;
    await result.when(
      success: (value) async => sensitive.value = value,
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> saveSensitive({
    String? sin,
    bool clearSin = false,
    Map<String, String>? banking,
    bool clearBanking = false,
  }) async {
    if (!canWritePii || sensitiveStaffId.value.isEmpty) {
      return 'You need staff PII write access.';
    }
    _beginBusy('revealSensitive');
    final result = await repository.updateStaffSensitive(
      staffId: sensitiveStaffId.value,
      sin: sin,
      clearSin: clearSin,
      banking: banking,
      clearBanking: clearBanking,
    );
    String? error;
    await result.when(
      success: (value) async => sensitive.value = value,
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<String?> exportPayrollCsv() async {
    if (!canReadPayroll) return 'You need payroll read access.';
    _beginBusy('exportPayroll');
    final result = await repository.exportPayrollEntries();
    String? error;
    await result.when(
      success: (job) async {
        lastPayrollExport.value = job;
        // Poll briefly so Download becomes available like web.
        if (!job.isReady) {
          await _loadExports();
        }
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<ResultOrError<List<int>>> downloadLastPayrollExport() async {
    final job = lastPayrollExport.value;
    if (job == null) {
      return const ResultOrError.error('No payroll export yet.');
    }
    _beginBusy('downloadPayroll');
    final result = await repository.downloadPayrollExport(job);
    _endBusy();
    return result.when(
      success: (bytes) => ResultOrError.value(bytes),
      failure: (e) => ResultOrError.error(e.message),
    );
  }

  Future<String?> setEntryPayment({
    required String entryId,
    required String status,
  }) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    if (!(engine.value?.runHere ?? false)) {
      final provider = engine.value?.provider ?? 'the payroll provider';
      return '${FinanceLabels.statusLabel(provider)} runs this organisation\'s '
          'payroll — pay, deductions, payslips and paying staff happen there. '
          'This platform sends it the hours.';
    }
    _beginBusy('setEntryPayment');
    final result = await repository.setEntryPayment(
      entryId: entryId,
      status: status,
    );
    String? error;
    await result.when(
      success: (_) async {
        final runId = selectedRun.value?.id ?? activeRun?.id;
        if (runId != null) await openRun(runId);
        await _loadRuns();
        _rebuildOverview();
      },
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  Future<ResultOrError<QuickBooksRunStatus>> loadQuickBooksRunStatus(
    String runId,
  ) async {
    final result = await repository.quickBooksRunStatus(runId);
    return result.when(
      success: (v) => ResultOrError.value(v),
      failure: (e) => ResultOrError.error(e.message),
    );
  }

  Future<String?> sendRunToQuickBooks(String runId) async {
    if (!canWritePayroll) return 'You need payroll write access.';
    _beginBusy('sendQb');
    final result = await repository.sendRunToQuickBooks(runId);
    String? error;
    await result.when(
      success: (_) async {},
      failure: (e) async => error = e.message,
    );
    _endBusy();
    return error;
  }

  /// Web `downloadCsv('residence-pnl-…')` column set.
  String pnlCsv() {
    final r = report.value;
    if (r == null || r.residences.isEmpty) return '';
    final buf = StringBuffer(
      'Residence,Occupancy %,Bed-nights,Accrued fees,Ledger revenue,Revenue,'
      'Labor,Inventory,Other costs,Total costs,Net,Margin %,'
      'Cost per day,Cost per bed-night,Cost per resident\n',
    );
    for (final row in r.residences) {
      buf.writeln(
        [
          _csvCell(row.residenceName),
          row.occupancyPercent.toStringAsFixed(1),
          row.occupiedBedNights,
          row.accruedFees.toStringAsFixed(2),
          row.ledgerRevenue.toStringAsFixed(2),
          row.revenueTotal.toStringAsFixed(2),
          row.payrollExpense.toStringAsFixed(2),
          row.inventoryExpense.toStringAsFixed(2),
          row.otherExpense.toStringAsFixed(2),
          row.expenseTotal.toStringAsFixed(2),
          row.netProfit.toStringAsFixed(2),
          row.margin?.toStringAsFixed(1) ?? '',
          row.costPerDay?.toStringAsFixed(2) ?? '',
          row.costPerBedNight?.toStringAsFixed(2) ?? '',
          row.costPerResident?.toStringAsFixed(2) ?? '',
        ].join(','),
      );
    }
    return buf.toString();
  }

  String pnlExportFileName() {
    return 'residence-pnl-${pnlFrom.value}-to-${pnlTo.value}.csv';
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

/// Tiny result helper for UI dialogs without importing gems Result.
class ResultOrError<T> {
  final T? value;
  final String? error;
  const ResultOrError.value(this.value) : error = null;
  const ResultOrError.error(this.error) : value = null;
}
