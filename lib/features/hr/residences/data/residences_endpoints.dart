abstract final class ResidencesEndpoints {
  static const String residences = '/residences';
  static const String clients = '/clients';
  static const String staff = '/staff';
  static const String shifts = '/shifts';
  static const String dailyLogs = '/daily-logs';
  static const String authMe = '/auth/me';
  static const String reportsExports = '/reports/exports';

  static String residence(String id) => '$residences/$id';
  static String status(String id) => '$residences/$id/status';
  static String assignments(String id) => '$residences/$id/assignments';
  static String payrollSettings(String id) =>
      '$residences/$id/payroll-settings';
  static String rooms(String id) => '$residences/$id/rooms';
  static String room(String id, String roomId) =>
      '$residences/$id/rooms/$roomId';
  static String reportsExport(String exportId) => '$reportsExports/$exportId';
  static String reportsExportDownload(String exportId) =>
      '$reportsExports/$exportId/download';
}
