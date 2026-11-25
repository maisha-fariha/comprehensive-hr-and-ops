/// Web `/dashboard/compliance` — Compliance & Audit.
abstract final class ComplianceEndpoints {
  static const overview = '/compliance/overview';
  static const score = '/compliance/score';
  static const alerts = '/compliance/alerts';
  static const requirements = '/compliance/requirements';
  static String requirement(String id) => '$requirements/$id';
  static String archiveRequirement(String id) => '$requirements/$id/archive';
  static String restoreRequirement(String id) => '$requirements/$id/restore';
  static const checks = '/compliance/checks';
  static String submitCheck(String id) => '$checks/$id/submit';
  static String reviewCheck(String id) => '$checks/$id/review';
  static const findings = '/compliance/findings';
  static String finding(String id) => '$findings/$id';
  static const correctiveActions = '/compliance/corrective-actions';
  static String correctiveAction(String id) => '$correctiveActions/$id';
  static String verifyAction(String id) => '$correctiveActions/$id/verify';
  static String restoreAction(String id) => '$correctiveActions/$id/restore';
  static const auditLogs = '/audit-logs';
  static const reportsExports = '/reports/exports';
  static const residences = '/residences';
  static const clients = '/clients';
  static const staff = '/staff';
}
