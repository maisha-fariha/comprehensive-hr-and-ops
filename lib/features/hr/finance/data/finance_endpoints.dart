/// Web Finance & Payroll API paths (`/dashboard/finance`, no billing).
abstract final class FinanceEndpoints {
  static const payrollRuns = '/payroll/runs';
  static String payrollRun(String id) => '$payrollRuns/$id';
  static String finalizeRun(String id) => '$payrollRuns/$id/finalize';
  static String payrollEntry(String id) => '/payroll/entries/$id';
  static const payrollEngine = '/payroll/engine';
  static const expenseClaims = '/payroll/expense-claims';
  static String approveExpenseClaim(String id) => '$expenseClaims/$id/approve';
  static const mileageClaims = '/payroll/mileage-claims';
  static String approveMileageClaim(String id) => '$mileageClaims/$id/approve';
  static const mileageRates = '/payroll/mileage-rates';
  static String mileageRate(String id) => '$mileageRates/$id';
  static const financeReport = '/finance/report';
  static const financeEntries = '/finance/entries';
  static String financeEntry(String id) => '$financeEntries/$id';
  static String clientCost(String clientId) => '/finance/clients/$clientId/cost';
  static const billingAddons = '/billing/addons';
  static const quickbooks = '/integrations/quickbooks';
  static const quickbooksConnect = '/integrations/quickbooks/connect';
  static const reportsExports = '/reports/exports';
  static String staffSensitive(String staffId) => '/staff/$staffId/sensitive';
  static const staff = '/staff';
  static const residences = '/residences';
  static const clients = '/clients';
}
