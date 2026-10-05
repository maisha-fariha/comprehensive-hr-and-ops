abstract final class AdmissionsEndpoints {
  static const String referrals = '/referrals';
  static const String board = '$referrals/board';
  static const String intakeTemplates = '/intake-templates';
  static const String residences = '/residences';

  static String referral(String id) => '$referrals/$id';
  static String contacts(String id) => '$referrals/$id/contacts';
  static String checklist(String id) => '$referrals/$id/checklist';
  static String assessments(String id) => '$referrals/$id/assessments';
  static String admit(String id) => '$referrals/$id/admit';
  static String decline(String id) => '$referrals/$id/decline';
  static String template(String id) => '$intakeTemplates/$id';
  static String rooms(String residenceId) => '$residences/$residenceId/rooms';
}
