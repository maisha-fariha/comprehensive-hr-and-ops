import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_daily_activity_option.dart';
import '../../domain/entities/staff_daily_activity_overview.dart';
import '../../domain/repositories/staff_daily_activity_repository.dart';
import '../mappers/staff_daily_activity_mapper.dart';

class StaffDailyActivityRepositoryImpl implements StaffDailyActivityRepository {
  final AppApiClient _api;

  StaffDailyActivityRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<StaffDailyActivityOverview>> getOverview({
    int page = 1,
    int limit = 20,
    String? search,
    String? clientId,
    String? recordedByStaffId,
    String? activityType,
    String? status,
    DateTime? date,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      if (recordedByStaffId != null && recordedByStaffId.isNotEmpty)
        'recordedByStaffId': recordedByStaffId,
      if (activityType != null && activityType.isNotEmpty)
        'activityType': activityType,
      if (status != null && status.isNotEmpty) 'status': status,
      if (date != null) ...{
        'from': _ymd(date),
        'to': _ymd(date),
      },
    };

    final result = await _api.get(
      ApiEndpoints.clientActivities,
      query: query,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffDailyActivityMapper.fromListBody(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDailyActivityPersonOption>>> getClientOptions() async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffDailyActivityMapper.peopleFrom(body, preferDisplayName: true),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffDailyActivityPersonOption>>> getStaffOptions() async {
    final result = await _api.get(
      ApiEndpoints.staff,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffDailyActivityMapper.peopleFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordActivity({
    required String clientId,
    required String activityDate,
    required String activityType,
    required String status,
    required String description,
    String? notes,
    String? recordedByStaffId,
    String? occurredAt,
    List<Map<String, String>>? attachments,
  }) async {
    final result = await _api.post(
      ApiEndpoints.clientActivities,
      data: {
        'clientId': clientId,
        'activityDate': activityDate,
        'activityType': activityType,
        'status': status,
        'description': description.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (recordedByStaffId != null && recordedByStaffId.isNotEmpty)
          'recordedByStaffId': recordedByStaffId,
        if (occurredAt != null && occurredAt.isNotEmpty) 'occurredAt': occurredAt,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> uploadDocument({
    required String localPath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'client-activities'},
        allowQueue: false,
      );
      return await result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          return Result.success(url);
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload $fileName: $error'),
      );
    }
  }

  static String _ymd(DateTime date) {
    final local = IsoDateRange.startOfLocalDay(date);
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }
}
