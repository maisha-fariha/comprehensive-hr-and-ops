import '../../../../core/network/api_endpoints.dart';

abstract final class HrTrainingEndpoints {
  static const String courses = ApiEndpoints.trainingCourses;
  static const String assignments = ApiEndpoints.trainingAssignments;
  static const String certificates = ApiEndpoints.trainingCertificates;
  static const String attempts = '/training/attempts';
  static const String auditLogs = '/audit-logs';
  static const String staff = '/staff';
  static const String staffCategories = '/staff-categories';
  static const String residences = ApiEndpoints.residences;
  static const String uploads = ApiEndpoints.uploads;

  static String course(String id) => '$courses/$id';
  static String courseQuiz(String id) => '$courses/$id/quiz';
  static String courseQuestions(String id) => '$courses/$id/questions';
  static String courseAttempts(String id) => '$courses/$id/attempts';
  static String assignment(String id) => '$assignments/$id';
  static String assignmentCertificate(String id) => '$assignments/$id/certificate';
  static String certificateReview(String id) => '$certificates/$id/review';
}
