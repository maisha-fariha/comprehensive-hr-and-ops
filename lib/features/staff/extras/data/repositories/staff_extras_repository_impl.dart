import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_shift_handover.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import '../mappers/staff_extras_mapper.dart';

class StaffExtrasRepositoryImpl implements StaffExtrasRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffExtrasRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
  }) async {
    final rid = residenceId ?? _session.residenceId;
    final result = await _api.get(
      ApiEndpoints.shiftHandovers,
      query: {
        if (rid != null && rid.isNotEmpty) 'residenceId': rid,
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((item) => StaffShiftHandover.fromJson(JsonCodec.asMap(item)))
            .where((item) => item.id.isNotEmpty)
            .toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffShiftHandover>> getHandoverDetail(
    String handoverId,
  ) async {
    final result = await _api.get(ApiEndpoints.handoverById(handoverId));
    return result.when(
      success: (body) async => Result.success(
        StaffShiftHandover.fromJson(StaffExtrasMapper.unwrap(body)),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> createHandover({
    required String residenceId,
    required String summary,
    bool submit = true,
    String? fromShiftId,
    String? toShiftId,
    List<Map<String, dynamic>> pendingActions = const [],
    List<Map<String, dynamic>> clientUpdates = const [],
    Map<String, dynamic>? flagForAttention,
  }) async {
    final result = await _api.post(
      ApiEndpoints.shiftHandovers,
      data: {
        'residenceId': residenceId,
        'summary': summary,
        'status': submit ? 'submitted' : 'draft',
        if (fromShiftId != null && fromShiftId.isNotEmpty)
          'fromShiftId': fromShiftId,
        if (toShiftId != null && toShiftId.isNotEmpty) 'toShiftId': toShiftId,
        if (pendingActions.isNotEmpty) 'pendingActions': pendingActions,
        if (clientUpdates.isNotEmpty) 'clientUpdates': clientUpdates,
        if (flagForAttention != null) 'flagForAttention': flagForAttention,
      },
    );
    return result.when(
      success: (body) async {
        final json = StaffExtrasMapper.unwrap(body);
        return Result.success(JsonCodec.stringOr(json['id'], ''));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  }) async {
    final result = await _api.post(
      ApiEndpoints.handoverAcknowledge(handoverId),
      data: {
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> deleteHandover(String handoverId) async {
    final result = await _api.delete(ApiEndpoints.handoverById(handoverId));
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.clientActivities,
      query: {'clientId': clientId},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'activityType',
          subtitleKeys: 'status,notes',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  }) async {
    final result = await _api.post(
      ApiEndpoints.clientActivities,
      data: {
        'clientId': clientId,
        'activityDate': IsoDateRange.todayDate,
        'activityType': activityType,
        'status': status,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      ApiEndpoints.inventoryItems,
      query: {'page': page, 'limit': limit},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'name,sku',
          subtitleKeys: 'quantity,unit,category',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getReferrals() async {
    final result = await _api.get(
      ApiEndpoints.referrals,
      query: const {'page': 1, 'limit': 30},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'prospectName,name,title',
          subtitleKeys: 'status,stage',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getCourseQuiz(String courseId) async {
    final result = await _api.get(ApiEndpoints.trainingCourseQuiz(courseId));
    return result.when(
      success: (body) async => Result.success(StaffExtrasMapper.unwrap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> submitQuizAttempt({
    required String courseId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final staffId = _session.staffId;
    final result = await _api.post(
      ApiEndpoints.trainingCourseAttempts(courseId),
      data: {
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        'answers': answers,
      },
    );
    return result.when(
      success: (body) async => Result.success(StaffExtrasMapper.unwrap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getTrainingCertificates() async {
    final result = await _api.get(
      ApiEndpoints.trainingCertificates,
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'courseName,title,name',
          subtitleKeys: 'issuedAt,expiresAt,status',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }
}
