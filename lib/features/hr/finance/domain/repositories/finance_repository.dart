import 'package:gems_core/gems_core.dart';

import '../entities/finance.dart';

/// Web `/dashboard/finance` (Finance & Payroll) — excluding billing.
abstract class FinanceRepository {
  Future<Result<FinancePageResult<PayrollRun>>> listRuns({
    int page = 1,
    int limit = 20,
  });

  Future<Result<PayrollRun>> getRun(String id);

  Future<Result<PayrollRun>> createRun({
    required String periodType,
    required String periodStart,
    required String periodEnd,
  });

  Future<Result<PayrollRun>> finalizeRun(String id);

  Future<Result<PayrollEntry>> adjustEntry({
    required String entryId,
    required double manualAdjustment,
    String? notes,
    String? adjustmentType,
    String? reason,
  });

  Future<Result<PayrollEngine>> engine();

  Future<Result<PayrollEngine>> setEngine({required bool runHere});

  Future<Result<FinancePageResult<PayrollClaim>>> expenseClaims({
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<Result<FinancePageResult<PayrollClaim>>> mileageClaims({
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<Result<PayrollClaim>> approveExpenseClaim({
    required String id,
    required String status,
  });

  Future<Result<PayrollClaim>> approveMileageClaim({
    required String id,
    required String status,
  });

  Future<Result<PayrollClaim>> createExpenseClaim({
    required String staffId,
    required String residenceId,
    required double amount,
    String? description,
  });

  Future<Result<PayrollClaim>> createMileageClaim({
    required String staffId,
    required String residenceId,
    required double distance,
    required String unit,
  });

  Future<Result<List<MileageRate>>> mileageRates();

  Future<Result<MileageRate>> createMileageRate({
    required String unit,
    required double rateAmount,
    required String effectiveFrom,
  });

  Future<Result<MileageRate>> endMileageRate({
    required String rateId,
    required String effectiveTo,
  });

  Future<Result<FinanceReport>> report({
    required String from,
    required String to,
    String? residenceId,
  });

  Future<Result<List<FinanceLedgerEntry>>> ledgerEntries({
    required String from,
    required String to,
    String? residenceId,
  });

  Future<Result<FinanceLedgerEntry>> createLedgerEntry({
    required String residenceId,
    required String entryType,
    required String category,
    required double amount,
    required String occurredOn,
    String? description,
  });

  Future<Result<void>> deleteLedgerEntry(String id);

  Future<Result<ClientCostSummary>> clientCost({
    required String clientId,
    required String from,
    required String to,
  });

  Future<Result<List<BillingAddon>>> addons();

  Future<Result<QuickBooksStatus>> quickBooksStatus();

  Future<Result<String>> quickBooksConnectUrl();

  Future<Result<StaffSensitiveInfo>> staffSensitive(
    String staffId, {
    bool reveal = false,
  });

  Future<Result<StaffSensitiveInfo>> updateStaffSensitive({
    required String staffId,
    String? sin,
    bool clearSin = false,
    Map<String, String>? banking,
    bool clearBanking = false,
  });

  Future<Result<List<FinancePersonOption>>> staffOptions();

  Future<Result<List<FinancePersonOption>>> residenceOptions();

  Future<Result<List<FinancePersonOption>>> clientOptions({
    String? residenceId,
  });

  Future<Result<FinanceExportJob>> exportPayrollEntries();

  Future<Result<List<FinanceExportJob>>> listPayrollExports();

  /// `GET /reports/exports/:id/download` (or preferred URL on the job).
  Future<Result<List<int>>> downloadPayrollExport(FinanceExportJob job);

  /// `POST /payroll/entries/:id/payment` — `{status: paid|failed|pending}`.
  Future<Result<PayrollEntry>> setEntryPayment({
    required String entryId,
    required String status,
  });

  Future<Result<QuickBooksRunStatus>> quickBooksRunStatus(String runId);

  /// `POST /integrations/quickbooks/runs/:id/send`.
  Future<Result<QuickBooksRunStatus>> sendRunToQuickBooks(String runId);
}
