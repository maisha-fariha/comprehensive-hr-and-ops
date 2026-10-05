import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/authorized_file.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/offline/offline_file_cache.dart';
import '../../domain/entities/daily_activity.dart';
import '../../domain/repositories/daily_activity_repository.dart';
import '../daily_activity_endpoints.dart';
import '../mappers/daily_activity_mapper.dart';

class DailyActivityRepositoryImpl implements DailyActivityRepository {
  final AppApiClient _api;

  DailyActivityRepositoryImpl({required AppApiClient api}) : _api = api;

  static const _pickerLimit = {'page': 1, 'limit': 100};

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  static String? _blank(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  @override
  Future<Result<DailyActivityListResult>> list({
    required int page,
    required int limit,
    String? search,
    String? clientId,
    String? recordedByStaffId,
    String? activityType,
    String? status,
    String? from,
    String? to,
  }) async {
    final result = await _api.get(
      DailyActivityEndpoints.activities,
      query: {
        'page': page,
        'limit': limit,
        'search': ?_blank(search),
        'clientId': ?_blank(clientId),
        'recordedByStaffId': ?_blank(recordedByStaffId),
        'activityType': ?_blank(activityType),
        'status': ?_blank(status),
        'from': ?from,
        'to': ?to,
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(DailyActivityMapper.pageFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<DailyActivityMonthSummary>> monthSummary({
    required String clientId,
    required String month,
  }) async {
    final result = await _api.get(
      DailyActivityEndpoints.summary,
      query: {'clientId': clientId, 'month': month},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(DailyActivityMapper.monthSummaryFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> create(DailyActivityDraft draft) async => _done(
        await _api.post(
          DailyActivityEndpoints.activities,
          data: draft.toJson(),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> update(String id, DailyActivityDraft draft) async => _done(
        await _api.patch(
          DailyActivityEndpoints.byId(id),
          data: draft.toJson(),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> markReviewed(String id) async => _done(
        await _api.patch(
          DailyActivityEndpoints.byId(id),
          data: const {'status': 'reviewed'},
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> delete(String id) async => _done(
        await _api.delete(
          DailyActivityEndpoints.byId(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<List<DailyActivityOption>>> clients() async {
    final result = await _api.get(
      DailyActivityEndpoints.clients,
      query: _pickerLimit,
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(DailyActivityMapper.clientsFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<DailyActivityOption>>> staff() async {
    final result = await _api.get(
      DailyActivityEndpoints.staff,
      query: _pickerLimit,
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(DailyActivityMapper.staffFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<String>> upload(DailyActivityLocalFile file) async {
    final FormData form;
    try {
      form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
    } catch (error) {
      return Result.failure(ApiError(message: 'Could not read ${file.name}'));
    }
    final result = await _api.post(
      DailyActivityEndpoints.uploads,
      data: form,
      query: const {'category': 'client-activities'},
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) {
        final url = JsonCodec.string(JsonCodec.unwrapMap(body)['fileUrl']);
        return url == null
            ? Result.failure(const ApiError(message: 'The upload returned no file link'))
            : Result.success(url);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<List<int>>> download(String fileUrl) =>
      OfflineFileCache.remember(
        'file:${fileUrl.trim()}',
        () => _download(fileUrl),
        source: fileUrl,
      );

  Future<Result<List<int>>> _download(String fileUrl) async {
    try {
      final response = await Dio().get<List<int>>(
        AuthorizedFile.resolveUrl(fileUrl),
        options: Options(
          responseType: ResponseType.bytes,
          headers: AuthorizedFile.headers(),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return Result.failure(const ApiError(message: 'The file was empty'));
      }
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(const ApiError(message: 'Could not download this file'));
    }
  }
}
