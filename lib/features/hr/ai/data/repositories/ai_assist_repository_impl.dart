import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/ai_assist.dart';
import '../../domain/repositories/ai_assist_repository.dart';
import '../mappers/ai_assist_mapper.dart';

class AiAssistRepositoryImpl implements AiAssistRepository {
  final AppApiClient _api;

  AiAssistRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<bool>> isDraftingEnabled() async {
    final result = await _api.get(ApiEndpoints.aiStatus, silent: true);
    return result.when(
      success: (body) async {
        final map = JsonCodec.unwrapMap(body);
        return Result.success(map['enabled'] == true);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiMarReview>> reviewMar({
    required String clientId,
    required int days,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiMarClientReview(clientId),
      data: {'days': days},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.marReviewFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiGoalsSuggestResult>> suggestGoals({
    required String clientId,
    String? notes,
    int count = 4,
  }) async {
    final trimmed = notes?.trim();
    final result = await _api.post(
      ApiEndpoints.aiClientGoalsSuggest(clientId),
      data: {
        'count': count,
        if (trimmed != null && trimmed.isNotEmpty) 'notes': trimmed,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.goalsSuggestFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiDraftResult>> summarizeDailyLogs({
    required String clientId,
    required int days,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiDailyLogsSummarize,
      data: {
        'clientId': clientId,
        'days': days,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.draftResultFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiAskDayAnswer>> askDay({
    required String clientId,
    required String logDate,
    required String query,
    required String preset,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiDailyLogsAskDay,
      data: {
        'clientId': clientId,
        'logDate': logDate,
        'query': query,
        'preset': preset,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.askDayFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiDailyLogDraftEntry>> draftDailyLogEntry({
    required String clientId,
    required String notes,
    String? logType,
    String? mood,
    String? sleep,
    String? hygiene,
  }) async {
    final options = <String, dynamic>{
      if (logType != null && logType.isNotEmpty) 'logType': logType,
      if (mood != null && mood.isNotEmpty) 'mood': mood,
      if (sleep != null && sleep.isNotEmpty) 'sleep': sleep,
      if (hygiene != null && hygiene.isNotEmpty) 'hygiene': hygiene,
    };
    final result = await _api.post(
      ApiEndpoints.aiDailyLogsDraftEntry,
      data: {
        'clientId': clientId,
        'notes': notes,
        if (options.isNotEmpty) 'options': options,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.dailyLogDraftFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiHandoverDraft>> draftHandover({
    required String residenceId,
    String? since,
    String? until,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiHandoversDraft,
      data: {
        'residenceId': residenceId,
        if (since != null && since.isNotEmpty) 'since': since,
        if (until != null && until.isNotEmpty) 'until': until,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.handoverDraftFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiDraftResult>> reviewGoals({
    required String clientId,
    required int days,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiClientGoalsReview(clientId),
      data: {'days': days},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.draftResultFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiRotaFindings>> reviewRota({
    required String residenceId,
    required String from,
    required int days,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiSchedulingReview,
      data: {
        'residenceId': residenceId,
        'from': from,
        'days': days,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.rotaReviewFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiTrainingGaps>> trainingGaps() async {
    final result = await _api.post(
      ApiEndpoints.aiTrainingGaps,
      data: const <String, dynamic>{},
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.trainingGapsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<AiStockReorder>> reviewStock({
    required String residenceId,
    required int days,
  }) async {
    final result = await _api.post(
      ApiEndpoints.aiInventoryReorder,
      data: {
        'residenceId': residenceId,
        'days': days,
      },
      allowQueue: false,
    );
    return result.when(
      success: (body) async =>
          Result.success(AiAssistMapper.stockReorderFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }
}
