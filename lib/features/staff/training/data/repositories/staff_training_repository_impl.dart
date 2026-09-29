import 'package:gems_core/gems_core.dart';

import '../../../../../../core/network/api_endpoints.dart';
import '../../../../../../core/network/app_api_client.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_training.dart';
import '../../domain/repositories/staff_training_repository.dart';
import '../mappers/staff_training_mapper.dart';

class StaffTrainingRepositoryImpl implements StaffTrainingRepository {
  final AppApiClient _api;

  StaffTrainingRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<StaffTrainingAssignmentsPage>> listAssignments({
    int page = 1,
    int limit = 20,
    String? courseId,
    String? staffId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.trainingAssignments,
      query: {
        'page': page,
        'limit': limit,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (raw) => StaffTrainingMapper.assignmentFromJson(
                JsonCodec.asMap(raw),
              ),
            )
            .toList();
        final meta = JsonCodec.metaOf(body) ?? const {};
        return Result.success(
          StaffTrainingAssignmentsPage(
            items: items,
            summary: StaffTrainingMapper.summaryFromMeta(meta),
            page: JsonCodec.integerOr(meta['page'], page),
            limit: JsonCodec.integerOr(meta['limit'], limit),
            total: JsonCodec.integerOr(meta['total'], items.length),
            totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffTrainingCoursesPage>> listCourses({
    int page = 1,
    int limit = 20,
    bool includeArchived = false,
  }) async {
    final result = await _api.get(
      ApiEndpoints.trainingCourses,
      query: {
        'page': page,
        'limit': limit,
        if (includeArchived) 'includeArchived': true,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (raw) => StaffTrainingMapper.courseFromJson(JsonCodec.asMap(raw)),
            )
            .toList();
        final meta = JsonCodec.metaOf(body) ?? const {};
        return Result.success(
          StaffTrainingCoursesPage(
            items: items,
            page: JsonCodec.integerOr(meta['page'], page),
            limit: JsonCodec.integerOr(meta['limit'], limit),
            total: JsonCodec.integerOr(meta['total'], items.length),
            totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffTrainingCourse>> getCourse(String id) async {
    final result = await _api.get(
      ApiEndpoints.trainingCourseById(id),
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffTrainingMapper.courseFromJson(
          JsonCodec.unwrapMap(body),
          includeAssignments: true,
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffTrainingCertificatesPageResult>> listCertificates({
    int page = 1,
    int limit = 50,
    String? courseId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.trainingCertificates,
      query: {
        'page': page,
        'limit': limit,
        if (courseId != null && courseId.isNotEmpty) 'courseId': courseId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (raw) => StaffTrainingMapper.certificateFromJson(
                JsonCodec.asMap(raw),
              ),
            )
            .toList();
        final meta = JsonCodec.metaOf(body) ?? const {};
        return Result.success(
          StaffTrainingCertificatesPageResult(
            items: items,
            page: JsonCodec.integerOr(meta['page'], page),
            limit: JsonCodec.integerOr(meta['limit'], limit),
            total: JsonCodec.integerOr(meta['total'], items.length),
            totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
