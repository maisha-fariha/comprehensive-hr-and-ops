/// API paths used by the Manager client directory (web `/dashboard/clients`).
abstract final class ClientsEndpoints {
  static const String clients = '/clients';
  static const String deletedClients = '$clients/deleted';
  static String client(String id) => '$clients/$id';
  static String restore(String id) => '$clients/$id/restore';
  static String transfer(String id) => '$clients/$id/transfer';

  static const String goalCategories = '/client-goals/categories';
  static String goals(String clientId) => '$clients/$clientId/goals';
  static String goal(String clientId, String goalId) => '${goals(clientId)}/$goalId';
  static String goalOutcomes(String clientId) => '${goals(clientId)}/outcomes';
  static String goalLogs(String clientId) => '${goals(clientId)}/logs';
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
