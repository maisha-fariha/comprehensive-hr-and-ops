import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_logs_repository.dart';
import '../mappers/daily_logs_mapper.dart';

class DailyLogsRepositoryImpl implements DailyLogsRepository {
  final AppApiClient _api;

  DailyLogsRepositoryImpl({required AppApiClient api}) : _api = api;

  Future<Result<T>> _get<T>(
    String path,
    Map<String, dynamic> query,
    T Function(dynamic body) map,
  ) async {
    final result = await _api.get(path, query: query, silent: true);
    return result.when(
      success: (body) async => Result.success(map(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Result<void>> _void(Future<Result<dynamic>> request) async {
    final result = await request;
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<DailyLogOption>>> residences() => _get(
        ApiEndpoints.residences,
        {'page': 1, 'limit': 100},
        DailyLogsMapper.residencesFrom,
      );

  @override
  Future<Result<List<DailyLogOption>>> clients(String? residenceId) => _get(
        ApiEndpoints.clients,
        {'residenceId': ?residenceId, 'page': 1, 'limit': 100},
        DailyLogsMapper.clientsFrom,
      );

  Map<String, dynamic> _queue({
    required String status,
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) =>
      {
        'residenceId': residenceId,
        'clientId': ?clientId,
        'from': from,
        'to': to,
        'status': status,
        'page': page,
        'limit': limit,
      };

  @override
  Future<Result<DailyLogPage<DailyLogReviewRow>>> reviewQueue({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) =>
      _get(
        ApiEndpoints.dailyLogs,
        _queue(
          status: 'review',
          residenceId: residenceId,
          clientId: clientId,
          from: from,
          to: to,
          page: page,
          limit: limit,
        ),
        DailyLogsMapper.reviewFrom,
      );

  @override
  Future<Result<DailyLogPage<DailyLogMissingRow>>> missing({
    required String residenceId,
    String? clientId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) =>
      _get(
        ApiEndpoints.dailyLogs,
        _queue(
          status: 'missing',
          residenceId: residenceId,
          clientId: clientId,
          from: from,
          to: to,
          page: page,
          limit: limit,
        ),
        DailyLogsMapper.missingFrom,
      );

  @override
  Future<Result<DailyLogDay?>> day({
    required String clientId,
    required String residenceId,
    required String logDate,
  }) =>
      _get(
        ApiEndpoints.dailyLogs,
        {'clientId': clientId, 'residenceId': residenceId, 'logDate': logDate},
        DailyLogsMapper.dayFrom,
      );

  @override
  Future<Result<DailyLogEntry>> entry(String id) => _get(
        ApiEndpoints.dailyLogEntryById(id),
        const {},
        (body) => DailyLogsMapper.entryFrom(JsonCodec.unwrapMap(body)),
      );

  @override
  Future<Result<List<DailyLogShiftRow>>> shiftLogs({
    required String residenceId,
    required String logDate,
  }) =>
      _get(
        ApiEndpoints.dailyLogShifts,
        {'residenceId': residenceId, 'logDate': logDate},
        DailyLogsMapper.shiftLogsFrom,
      );

  @override
  Future<Result<void>> updateShiftLog(String id, Map<String, dynamic> body) => _void(
        _api.patch(ApiEndpoints.dailyLogShiftById(id),
            data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<void>> createEntry(Map<String, dynamic> body) => _void(
        _api.post(ApiEndpoints.dailyLogEntries, data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<void>> amendEntry(String id, {required String body, required String reason}) =>
      _void(
        _api.post(ApiEndpoints.dailyLogAmendments(id),
            data: {'body': body, 'reason': reason}, silent: true, allowQueue: false),
      );

  @override
  Future<Result<void>> deleteEntry(String id) => _void(
        _api.delete(ApiEndpoints.dailyLogEntryById(id), silent: true, allowQueue: false),
      );

  @override
  Future<Result<DailyLogPage<ResidenceActivityRow>>> activity({
    required String residenceId,
    required String from,
    required String to,
    required int page,
    required int limit,
  }) =>
      _get(
        ApiEndpoints.residenceActivity,
        {'residenceId': residenceId, 'from': from, 'to': to, 'page': page, 'limit': limit},
        DailyLogsMapper.activityFrom,
      );

  @override
  Future<Result<DailyLogPage<CareFlag>>> openFlags(String? residenceId) => _get(
        ApiEndpoints.careFlags,
        {'residenceId': ?residenceId, 'state': 'open', 'limit': 20},
        DailyLogsMapper.flagsFrom,
      );

  @override
  Future<Result<void>> resolveFlag(String id, {String? note}) => _void(
        _api.post(ApiEndpoints.careFlagResolve(id),
            data: {'note': ?note}, silent: true, allowQueue: false),
      );

  @override
  Future<Result<DailyLogUpload>> upload(String path, String fileName) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: {'category': 'daily-log-attachment'},
        silent: true,
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final upload = DailyLogsMapper.uploadFrom(body, fileName);
          return upload == null
              ? Result.failure(
                  const ApiError(message: 'Upload succeeded but file URL was missing.'),
                )
              : Result.success(upload);
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(ApiError(message: 'Could not upload $fileName: $error'));
    }
  }
}
