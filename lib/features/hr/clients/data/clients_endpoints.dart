/// API paths used by the Manager client directory (web `/dashboard/clients`).
abstract final class ClientsEndpoints {
  static const String clients = '/clients';
  static String client(String id) => '$clients/$id';
  static String transfer(String id) => '$clients/$id/transfer';
  static String family(String clientId) => '$clients/$clientId/family';
  static String familyMember(String clientId, String memberId) =>
      '$clients/$clientId/family/$memberId';

  static const String residences = '/residences';
  static String rooms(String residenceId) => '$residences/$residenceId/rooms';

  static String clientSpend(String clientId) =>
      '/inventory/client-spend/$clientId';

  /// `data.tenant.limits.clients` is the plan's client cap.
  static const String me = '/auth/me';

  static const String uploads = '/uploads';
  static const String documents = '/documents';

  static const String reportExports = '/reports/exports';
  static String reportExport(String id) => '$reportExports/$id';
  static String reportExportDownload(String id) =>
      '$reportExports/$id/download';
}
