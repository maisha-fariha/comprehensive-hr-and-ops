import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';
import '../mappers/staff_daily_logs_mapper.dart';

class StaffDailyLogsRepositoryImpl implements StaffDailyLogsRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffDailyLogsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffDailyLogsOverview>> getOverview() async {
    final clients = await _api.get(
      ApiEndpoints.clients,
      query: {
        'assignedToMe': true,
        'page': 1,
        'limit': 20,
        'residenceId': ?_session.residenceId,
      },
    );
    if (clients.isFailure) {
      return Result.failure(
        clients.error ??
            const ApiError(message: 'Could not load assigned clients.'),
      );
    }

    final clientMaps = JsonCodec.unwrapList(clients.value).whereType<Map>();
    String? residenceId = _session.residenceId;
    if (residenceId == null || residenceId.isEmpty) {
      for (final raw in clientMaps) {
        final json = JsonCodec.asMap(raw);
        residenceId = JsonCodec.string(
          json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
        );
        if (residenceId != null) break;
      }
    }

    final logResults = await Future.wait(
      clientMaps.take(20).map((raw) {
        final json = JsonCodec.asMap(raw);
        final clientId = JsonCodec.string(json['id']);
        final rid = JsonCodec.string(
              json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
            ) ??
            residenceId;
        return _api.get(
          ApiEndpoints.dailyLogs,
          query: {
            'clientId': clientId,
            'residenceId': rid,
            'logDate': IsoDateRange.todayDate,
          },
        );
      }),
    );

    final flags = await _api.get(
      ApiEndpoints.careFlags,
      query: {
        'page': 1,
        'limit': 20,
        'state': 'open',
        'residenceId': ?residenceId,
      },
    );

    return Result.success(
      StaffDailyLogsMapper.compose(
        clientsBody: clients.value,
        logBodies: [for (final result in logResults) result.value],
        flagsBody: flags.value,
      ),
    );
  }

  @override
  Future<Result<DailyNoteOverview>> getDailyNoteOverview() async {
    return Result.success(StaffDailyLogsMapper.emptyNote());
  }

  @override
  Future<Result<String>> saveEntry({
    required String clientId,
    required String residenceId,
    required String body,
    String? entryId,
    required bool submit,
    Map<String, String>? observations,
    bool flagForAttention = false,
  }) async {
    final payload = <String, dynamic>{
      'clientId': clientId,
      'residenceId': residenceId,
      'logDate': IsoDateRange.todayDate,
      'body': body,
      'status': submit ? 'submitted' : 'draft',
      'flagForAttention': flagForAttention,
      'shift': _shiftForNow(),
      if (observations != null && observations.isNotEmpty)
        'observations': {
          'mood': ?observations['mood'],
          'meals': ?observations['meals'],
          'sleep': ?observations['sleep'],
          'hygiene': ?observations['hygiene'],
          'activities': ?observations['activities'],
          'behaviorNotes': ?observations['behavior'],
          'wellness': ?observations['wellness'],
        },
    };

    final result = entryId == null || entryId.isEmpty
        ? await _api.post(ApiEndpoints.dailyLogEntries, data: payload)
        : await _api.patch(
            ApiEndpoints.dailyLogEntryById(entryId),
            data: {
              'body': body,
              'status': submit ? 'submitted' : 'draft',
              'flagForAttention': flagForAttention,
              if (observations != null && observations.isNotEmpty)
                'observations': payload['observations'],
            },
          );

    return result.when(
      success: (value) async {
        final json = JsonCodec.unwrapMap(value);
        return Result.success(
          JsonCodec.stringOr(json['id'] ?? json['entryId'] ?? entryId, ''),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createHandover({
    required String residenceId,
    required String notes,
    String? clientId,
  }) async {
    final result = await _api.post(
      ApiEndpoints.shiftHandovers,
      data: {
        'residenceId': residenceId,
        'notes': notes,
        'body': notes,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  static String _shiftForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'night';
  }
}
