import 'package:flutter/foundation.dart';

/// `GET /payroll/engine` — which system runs payroll for this tenant.
@immutable
class PayrollEngine {
  final String engine;
  final String provider;
  final bool runHere;

  const PayrollEngine({
    required this.engine,
    required this.provider,
    required this.runHere,
  });
}

/// One staff line on a payroll run (`entries[]`).
@immutable
class PayrollEntry {
  final String id;
  final String staffId;
  final String staffName;
  final String? staffRole;
  final String? employmentBasis;
  final String residenceName;
  final double hours;
  final double overtimeHours;
  final double overtimeAmount;
  final double? hourlyRate;
  final double baseAmount;
  final double grossAmount;
  final double netAmount;
  final double manualAdjustment;
  final double allowances;
  final double deductions;
  final String paymentStatus;

  const PayrollEntry({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.hours,
    required this.overtimeHours,
    required this.overtimeAmount,
    required this.baseAmount,
    required this.grossAmount,
    required this.netAmount,
    required this.manualAdjustment,
    required this.allowances,
    required this.deductions,
    required this.paymentStatus,
    this.staffRole,
    this.employmentBasis,
    this.residenceName = '—',
    this.hourlyRate,
  });

  double get totalPay => grossAmount + manualAdjustment;
}

/// Paginated list envelope used by runs / claims.
@immutable
class FinancePageResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const FinancePageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

/// `GET /payroll/runs` item (and `GET /payroll/runs/:id`).
@immutable
class PayrollRun {
  final String id;
  final String periodType;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String status;
  final DateTime? createdAt;
  final List<PayrollEntry> entries;
  final int claimsCount;
  final double hoursTotal;

  const PayrollRun({
    required this.id,
    required this.periodType,
    required this.status,
    this.periodStart,
    this.periodEnd,
    this.createdAt,
    this.entries = const [],
    this.claimsCount = 0,
    this.hoursTotal = 0,
  });

  double get grossTotal =>
      entries.fold(0, (sum, e) => sum + e.grossAmount + e.manualAdjustment);

  double get adjustmentsTotal =>
      entries.fold(0, (sum, e) => sum + e.manualAdjustment);

  int get staffCount => entries.isEmpty ? 0 : entries.length;
}

/// Pending claim row shared by expense + mileage lists.
@immutable
class PayrollClaim {
  final String id;
  final String kind; // expense | mileage
  final String status;
  final String staffName;
  final String? staffId;
  final double amount;
  final String? description;
  final String? category;
  final DateTime? createdAt;
  final double? distance;
  final String? distanceUnit;
  final String? payrollRunId;
  final String? payrollRunLabel;

  const PayrollClaim({
    required this.id,
    required this.kind,
    required this.status,
    required this.staffName,
    required this.amount,
    this.staffId,
    this.description,
    this.category,
    this.createdAt,
    this.distance,
    this.distanceUnit,
    this.payrollRunId,
    this.payrollRunLabel,
  });
}

@immutable
class MileageRate {
  final String id;
  final String unit;
  final double rateAmount;
  final String currency;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  const MileageRate({
    required this.id,
    required this.unit,
    required this.rateAmount,
    this.currency = 'USD',
    this.effectiveFrom,
    this.effectiveTo,
  });

  bool get isActive =>
      effectiveTo == null || effectiveTo!.isAfter(DateTime.now());
}

/// One residence block from `GET /finance/report`.
@immutable
class ResidencePnL {
  final String residenceId;
  final String residenceName;
  final double revenueTotal;
  final double expenseTotal;
  final double payrollExpense;
  final double inventoryExpense;
  final double otherExpense;
  final double netProfit;
  final double? margin;
  final double occupancyPercent;
  final int occupiedBedNights;
  final int residents;
  final double? averageResidents;
  final double? costPerBedNight;
  final double? costPerResident;
  final String? revenueDetail;

  const ResidencePnL({
    required this.residenceId,
    required this.residenceName,
    required this.revenueTotal,
    required this.expenseTotal,
    required this.payrollExpense,
    required this.inventoryExpense,
    required this.otherExpense,
    required this.netProfit,
    required this.occupancyPercent,
    required this.occupiedBedNights,
    required this.residents,
    this.margin,
    this.averageResidents,
    this.costPerBedNight,
    this.costPerResident,
    this.revenueDetail,
  });
}

@immutable
class FinanceReport {
  final DateTime? from;
  final DateTime? to;
  final List<ResidencePnL> residences;
  final double revenueTotal;
  final double expenseTotal;
  final double payrollTotal;
  final double netProfit;
  final double? margin;
  final double? costPerBedNight;
  final double? costPerResident;
  final int bedNights;
  final double? averageResidents;

  const FinanceReport({
    required this.residences,
    required this.revenueTotal,
    required this.expenseTotal,
    required this.payrollTotal,
    required this.netProfit,
    this.from,
    this.to,
    this.margin,
    this.costPerBedNight,
    this.costPerResident,
    this.bedNights = 0,
    this.averageResidents,
  });
}

@immutable
class FinanceLedgerEntry {
  final String id;
  final String entryType;
  final String category;
  final double amount;
  final String? description;
  final String? residenceId;
  final String? residenceName;
  final DateTime? occurredOn;

  const FinanceLedgerEntry({
    required this.id,
    required this.entryType,
    required this.category,
    required this.amount,
    this.description,
    this.residenceId,
    this.residenceName,
    this.occurredOn,
  });
}

/// KPI strip on web Payroll Overview.
@immutable
class PayrollOverviewStats {
  final double totalPayroll;
  final double staffHours;
  final double overtimeHours;
  final double overtimeCost;
  final int pendingApprovals;
  final int draftRuns;
  final int staffOnRun;
  final double reimbursements;
  final int reimbursementClaims;
  final double costPerClient;
  final int residentCount;
  final String runStatus;
  final String? payPeriodLabel;
  final String? engineLabel;

  const PayrollOverviewStats({
    required this.totalPayroll,
    required this.staffHours,
    required this.overtimeHours,
    required this.overtimeCost,
    required this.pendingApprovals,
    required this.draftRuns,
    required this.staffOnRun,
    required this.reimbursements,
    required this.reimbursementClaims,
    required this.costPerClient,
    required this.residentCount,
    required this.runStatus,
    this.payPeriodLabel,
    this.engineLabel,
  });
}

@immutable
class FinancePersonOption {
  final String id;
  final String name;
  final String? paymentDuration;
  final bool mileageEnabled;
  final bool outOfPocketEnabled;

  const FinancePersonOption({
    required this.id,
    required this.name,
    this.paymentDuration,
    this.mileageEnabled = false,
    this.outOfPocketEnabled = false,
  });
}

@immutable
class BillingAddon {
  final String key;
  final String name;
  final String description;
  final String state;
  final double? price;
  final String billingMode;
  final bool grantedByUs;
  final bool canBuy;

  const BillingAddon({
    required this.key,
    required this.name,
    required this.description,
    required this.state,
    required this.billingMode,
    this.price,
    this.grantedByUs = false,
    this.canBuy = false,
  });
}

@immutable
class QuickBooksStatus {
  final bool configured;
  final bool connected;
  final String status;
  final String? companyName;
  final String? lastError;

  const QuickBooksStatus({
    required this.configured,
    required this.connected,
    required this.status,
    this.companyName,
    this.lastError,
  });
}

@immutable
class StaffSensitiveInfo {
  final String staffId;
  final bool revealed;
  final bool sinOnFile;
  final String? sinMasked;
  final String? sinValue;
  final bool bankingOnFile;
  final String? institutionNumber;
  final String? transitNumber;
  final String? accountNumber;
  final String? accountMasked;

  const StaffSensitiveInfo({
    required this.staffId,
    required this.revealed,
    required this.sinOnFile,
    required this.bankingOnFile,
    this.sinMasked,
    this.sinValue,
    this.institutionNumber,
    this.transitNumber,
    this.accountNumber,
    this.accountMasked,
  });
}

@immutable
class ClientCostSummary {
  final String clientId;
  final String clientName;
  final String? residenceName;
  final int nights;
  final double costTotal;
  final double revenueTotal;
  final double variance;
  final double overheadShare;
  final String? fundingSource;

  const ClientCostSummary({
    required this.clientId,
    required this.clientName,
    required this.nights,
    required this.costTotal,
    required this.revenueTotal,
    required this.variance,
    required this.overheadShare,
    this.residenceName,
    this.fundingSource,
  });
}

@immutable
class FinanceExportJob {
  final String id;
  final String reportKey;
  final String status;
  final DateTime? createdAt;
  final String? fileUrl;

  const FinanceExportJob({
    required this.id,
    required this.reportKey,
    required this.status,
    this.createdAt,
    this.fileUrl,
  });
}
