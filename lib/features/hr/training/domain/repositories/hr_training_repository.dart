import 'package:gems_core/gems_core.dart';

import '../entities/hr_training.dart';

/// Web `trainingService` (`/dashboard/training` and its course detail page).
abstract class HrTrainingRepository {
  /// `GET /training/courses?includeArchived&page&limit`.
  Future<Result<TrainingPage<TrainingCourse>>> courses({
    required bool includeArchived,
    required int page,
    required int limit,
  });

  /// `GET /training/courses/:id` (carries its assignments).
  Future<Result<TrainingCourse>> course(String id);

  /// `POST /training/courses`; returns the new course.
  Future<Result<TrainingCourse>> createCourse(Map<String, dynamic> body);

  /// `PATCH /training/courses/:id`.
  Future<Result<void>> updateCourse(String id, Map<String, dynamic> body);

  /// `DELETE /training/courses/:id`.
  Future<Result<void>> removeCourse(String id);

  /// `GET /training/courses/:id/quiz` (no answer key).
  Future<Result<TrainingQuiz>> quiz(String courseId);

  /// `GET /training/courses/:id/questions` (`training:manage`, with answers).
  Future<Result<List<TrainingQuestion>>> authoredQuestions(String courseId);

  /// `PUT /training/courses/:id/questions` — replaces the whole quiz.
  Future<Result<void>> setQuestions(String courseId, Map<String, dynamic> body);

  /// `GET /training/assignments` (`meta.summary` carries the KPI counts).
  Future<Result<TrainingPage<TrainingAssignment>>> assignments({
    String? courseId,
    int? page,
    required int limit,
  });

  /// `POST /training/assignments`; returns the written assignments.
  Future<Result<List<TrainingAssignment>>> assign({
    required String courseId,
    required List<String> staffIds,
    required bool mandatory,
    String? dueAt,
  });

  /// `PATCH /training/assignments/:id`.
  Future<Result<void>> updateAssignment(String id, Map<String, dynamic> body);

  /// `POST /training/assignments/:id/certificate`.
  Future<Result<void>> submitCertificate(
    String assignmentId,
    Map<String, dynamic> body,
  );

  /// `GET /training/attempts?courseId&page&limit`.
  Future<Result<TrainingPage<TrainingAttempt>>> attempts({
    required String courseId,
    required int page,
    required int limit,
  });

  /// `POST /training/courses/:id/attempts` — marked by the API.
  Future<Result<TrainingAttemptResult>> submitAttempt(
    String courseId, {
    required String staffId,
    required List<Map<String, dynamic>> answers,
  });

  /// `GET /training/certificates?courseId&page&limit`.
  Future<Result<TrainingPage<TrainingCertificate>>> certificates({
    required String courseId,
    required int page,
    required int limit,
  });

  /// `POST /training/certificates/:id/review`.
  Future<Result<void>> reviewCertificate(
    String certificateId,
    Map<String, dynamic> body,
  );

  /// `GET /audit-logs?module=training&entityId&limit=50` (`compliance:read`).
  Future<Result<List<TrainingAuditEntry>>> auditLogs(String courseId);

  /// `GET /staff?page=1&limit=100` (`staff:read`).
  Future<Result<List<TrainingStaffOption>>> staff();

  /// `GET /staff-categories` (`staff-categories:read`), active ones only.
  Future<Result<List<TrainingOption>>> staffCategories();

  /// `GET /residences?page=1&limit=100` (`residences:read`).
  Future<Result<List<TrainingOption>>> residences();

  /// `POST /uploads?category=training`; returns the stored file URL.
  Future<Result<String>> uploadMaterial(String path, String fileName);
}
