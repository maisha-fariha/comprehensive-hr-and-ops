/// Paths used by the web `/dashboard/medication` (MAR) screen.
abstract final class MedicationEndpoints {
  static const String round = '/mar/round';
  static const String administrations = '/mar/administrations';
  static const String administrationRound = '/mar/administrations/round';
  static String amendments(String administrationId) =>
      '/mar/administrations/$administrationId/amendments';
  static String residentChart(String clientId) => '/mar/residents/$clientId/chart';
  static const String witnesses = '/mar/witnesses';

  static const String medications = '/medications';
  static const String medicationBatch = '/medications/batch';
  static String medication(String id) => '/medications/$id';
  static String discontinueMedication(String id) => '/medications/$id/discontinue';

  static const String prnMedications = '/prn-medications';
  static const String prnBatch = '/prn-medications/batch';
  static String prnMedication(String id) => '/prn-medications/$id';
  static String discontinuePrn(String id) => '/prn-medications/$id/discontinue';

  static const String residences = '/residences';
  static const String clients = '/clients';
  static const String staff = '/staff';
  static const String checkSchedules = '/recurring-checks/schedules';
  static const String uploads = '/uploads';
  static const String documents = '/documents';

  static const String reportExports = '/reports/exports';
  static String reportExport(String id) => '/reports/exports/$id';
  static String reportExportDownload(String id) => '/reports/exports/$id/download';

  /// The web's `MAX_PAGE_LIMIT`.
  static const int maxPageLimit = 100;
}
