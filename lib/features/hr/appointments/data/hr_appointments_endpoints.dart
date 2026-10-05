/// Paths used by the web `/dashboard/appointments` screen.
abstract final class HrAppointmentsEndpoints {
  static const String appointments = '/appointments';
  static const String summary = '/appointments/summary';
  static String byId(String id) => '/appointments/$id';
  static String approve(String id) => '/appointments/$id/approve';
  static String reject(String id) => '/appointments/$id/reject';
  static String cancel(String id) => '/appointments/$id/cancel';
  static String reschedule(String id) => '/appointments/$id/reschedule';

  static const String residences = '/residences';
  static const String clients = '/clients';
  static const String dailyLogs = '/daily-logs';

  static const String reportExports = '/reports/exports';
  static String reportExport(String id) => '/reports/exports/$id';
  static String reportExportDownload(String id) => '/reports/exports/$id/download';

  /// The web's `MAX_PAGE_LIMIT`.
  static const int maxPageLimit = 100;
}
