import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/hr_training.dart';
import '../../domain/repositories/hr_training_repository.dart';
import '../hr_training_endpoints.dart';
import '../mappers/hr_training_mapper.dart';

class HrTrainingRepositoryImpl implements HrTrainingRepository {
  final AppApiClient _api;

  HrTrainingRepositoryImpl({required AppApiClient api}) : _api = api;

  static const int _maxLimit = 100;

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  Future<Result<T>> _get<T>(
    String path,
    T Function(dynamic body) map, {
    Map<String, dynamic>? query,
  }) async {
    final result = await _api.get(path, query: query, silent: true);
    return result.when(
      success: (body) => Result.success(map(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<TrainingPage<TrainingCourse>>> courses({
    required bool includeArchived,
    required int page,
    required int limit,
  }) =>
      _get(
        HrTrainingEndpoints.courses,
        HrTrainingMapper.coursesFrom,
        query: {'includeArchived': includeArchived, 'page': page, 'limit': limit},
      );

  @override
  Future<Result<TrainingCourse>> course(String id) async {
    final result = await _api.get(HrTrainingEndpoints.course(id), silent: true);
    return result.when(
      success: (body) {
        final course = HrTrainingMapper.courseFrom(JsonCodec.unwrapMap(body));
        return course == null
            ? Result.failure(const ApiError(message: 'Course could not be read'))
            : Result.success(course);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<TrainingCourse>> createCourse(Map<String, dynamic> body) async {
    final result = await _api.post(
      HrTrainingEndpoints.courses,
      data: body,
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (raw) {
        final course = HrTrainingMapper.courseFrom(JsonCodec.unwrapMap(raw));
        return course == null
            ? Result.failure(const ApiError(message: 'Course could not be read'))
            : Result.success(course);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> updateCourse(String id, Map<String, dynamic> body) async =>
      _done(
        await _api.patch(
          HrTrainingEndpoints.course(id),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> removeCourse(String id) async => _done(
        await _api.delete(
          HrTrainingEndpoints.course(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<TrainingQuiz>> quiz(String courseId) => _get(
        HrTrainingEndpoints.courseQuiz(courseId),
        (body) => HrTrainingMapper.quizFrom(body, courseId),
      );

  @override
  Future<Result<List<TrainingQuestion>>> authoredQuestions(String courseId) =>
      _get(
        HrTrainingEndpoints.courseQuestions(courseId),
        HrTrainingMapper.questionsFrom,
      );

  @override
  Future<Result<void>> setQuestions(
    String courseId,
    Map<String, dynamic> body,
  ) async =>
      _done(
        await _api.put(
          HrTrainingEndpoints.courseQuestions(courseId),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<TrainingPage<TrainingAssignment>>> assignments({
    String? courseId,
    int? page,
    required int limit,
  }) =>
      _get(
        HrTrainingEndpoints.assignments,
        HrTrainingMapper.assignmentsFrom,
        query: {'courseId': ?courseId, 'page': ?page, 'limit': limit},
      );

  @override
  Future<Result<List<TrainingAssignment>>> assign({
    required String courseId,
    required List<String> staffIds,
    required bool mandatory,
    String? dueAt,
  }) async {
    final result = await _api.post(
      HrTrainingEndpoints.assignments,
      data: {
        'courseId': courseId,
        'staffIds': staffIds,
        'mandatory': mandatory,
        'dueAt': ?dueAt,
      },
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) =>
          Result.success(HrTrainingMapper.assignmentListFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> updateAssignment(
    String id,
    Map<String, dynamic> body,
  ) async =>
      _done(
        await _api.patch(
          HrTrainingEndpoints.assignment(id),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> submitCertificate(
    String assignmentId,
    Map<String, dynamic> body,
  ) async =>
      _done(
        await _api.post(
          HrTrainingEndpoints.assignmentCertificate(assignmentId),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<TrainingPage<TrainingAttempt>>> attempts({
    required String courseId,
    required int page,
    required int limit,
  }) =>
      _get(
        HrTrainingEndpoints.attempts,
        HrTrainingMapper.attemptsFrom,
        query: {'courseId': courseId, 'page': page, 'limit': limit},
      );

  @override
  Future<Result<TrainingAttemptResult>> submitAttempt(
    String courseId, {
    required String staffId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final result = await _api.post(
      HrTrainingEndpoints.courseAttempts(courseId),
      data: {'staffId': staffId, 'answers': answers},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) {
        final parsed = HrTrainingMapper.attemptResultFrom(body);
        return parsed == null
            ? Result.failure(const ApiError(message: 'Sitting could not be read'))
            : Result.success(parsed);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<TrainingPage<TrainingCertificate>>> certificates({
    required String courseId,
    required int page,
    required int limit,
  }) =>
      _get(
        HrTrainingEndpoints.certificates,
        HrTrainingMapper.certificatesFrom,
        query: {'courseId': courseId, 'page': page, 'limit': limit},
      );

  @override
  Future<Result<void>> reviewCertificate(
    String certificateId,
    Map<String, dynamic> body,
  ) async =>
      _done(
        await _api.post(
          HrTrainingEndpoints.certificateReview(certificateId),
          data: body,
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<List<TrainingAuditEntry>>> auditLogs(String courseId) => _get(
        HrTrainingEndpoints.auditLogs,
        HrTrainingMapper.auditLogsFrom,
        query: {'module': 'training', 'entityId': courseId, 'limit': 50},
      );

  @override
  Future<Result<List<TrainingStaffOption>>> staff() => _get(
        HrTrainingEndpoints.staff,
        HrTrainingMapper.staffFrom,
        query: const {'page': 1, 'limit': _maxLimit},
      );

  @override
  Future<Result<List<TrainingOption>>> staffCategories() => _get(
        HrTrainingEndpoints.staffCategories,
        (body) => HrTrainingMapper.optionsFrom(body, activeOnly: true),
      );

  @override
  Future<Result<List<TrainingOption>>> residences() => _get(
        HrTrainingEndpoints.residences,
        HrTrainingMapper.optionsFrom,
        query: const {'page': 1, 'limit': _maxLimit},
      );

  @override
  Future<Result<String>> uploadMaterial(String path, String fileName) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      });
      final result = await _api.post(
        HrTrainingEndpoints.uploads,
        data: form,
        query: const {'category': 'training'},
        silent: true,
        allowQueue: false,
      );
      return result.when(
        success: (body) {
          final url = HrTrainingMapper.uploadUrlFrom(body);
          return url == null
              ? Result.failure(
                  const ApiError(message: 'Upload succeeded but file URL was missing.'),
                )
              : Result.success(url);
        },
        failure: Result.failure,
      );
    } catch (error) {
      return Result.failure(ApiError(message: 'Could not upload $fileName: $error'));
    }
  }
}
