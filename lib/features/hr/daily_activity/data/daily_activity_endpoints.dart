/// Paths for the manager Daily Activity screen (web `/dashboard/daily-activity`).
abstract final class DailyActivityEndpoints {
  static const String activities = '/client-activities';
  static const String summary = '/client-activities/summary';
  static const String clients = '/clients';
  static const String staff = '/staff';
  static const String uploads = '/uploads';

  static String byId(String id) => '$activities/$id';
}
