import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../domain/entities/recurring_check.dart';
import '../../domain/repositories/recurring_checks_repository.dart';
import '../mappers/recurring_checks_mapper.dart';

class RecurringChecksRepositoryImpl implements RecurringChecksRepository {
  final AppApiClient _api;

  RecurringChecksRepositoryImpl({required AppApiClient api}) : _api = api;

  Future<Result<T>> _get<T>(
    String path,
    Map<String, dynamic> query,
    T Function(dynamic body) map, {
    bool silent = true,
  }) async {
    final result = await _api.get(path, query: query, silent: silent);
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
  Future<Result<CheckSchedulePage>> schedules({required int page, required int limit}) =>
      _get(
        ApiEndpoints.recurringCheckSchedules,
        {'page': page, 'limit': limit},
        (body) => RecurringChecksMapper.schedulePageFrom(body, page: page, limit: limit),
        silent: false,
      );

  @override
  Future<Result<List<CheckSchedule>>> clientSchedules(String clientId) => _get(
        ApiEndpoints.recurringCheckSchedules,
        {'clientId': clientId, 'limit': 50},
        RecurringChecksMapper.schedulesFrom,
      );

  @override
  Future<Result<void>> createSchedule(Map<String, dynamic> body) => _void(
        _api.post(ApiEndpoints.recurringCheckSchedules,
            data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<void>> updateSchedule(String id, Map<String, dynamic> body) => _void(
        _api.patch(ApiEndpoints.recurringCheckScheduleById(id),
            data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<void>> deleteSchedule(String id) => _void(
        _api.delete(ApiEndpoints.recurringCheckScheduleById(id),
            silent: true, allowQueue: false),
      );

  @override
  Future<Result<List<CheckInstance>>> instances({
    required String day,
    String? residenceId,
    String? status,
    bool mine = false,
  }) =>
      _get(
        ApiEndpoints.recurringCheckInstances,
        {
          'residenceId': ?residenceId,
          'status': ?status,
          'from': day,
          'to': day,
          if (mine) 'mine': true,
          'page': 1,
          'limit': 100,
        },
        RecurringChecksMapper.instancesFrom,
      );

  @override
  Future<Result<List<CheckEntry>>> entries({
    required String day,
    String? residenceId,
    String? outcome,
    bool mine = false,
  }) =>
      _get(
        ApiEndpoints.recurringCheckEntries,
        {
          'residenceId': ?residenceId,
          'outcome': ?outcome,
          'from': day,
          'to': day,
          if (mine) 'mine': true,
          'page': 1,
          'limit': 100,
        },
        RecurringChecksMapper.entriesFrom,
      );

  @override
  Future<Result<void>> updateInstance(String id, Map<String, dynamic> body) => _void(
        _api.patch(ApiEndpoints.recurringCheckInstanceById(id),
            data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<List<CheckAvailableStaff>>> availableStaff(String instanceId) => _get(
        ApiEndpoints.recurringCheckAvailableStaff(instanceId),
        const {},
        RecurringChecksMapper.availableStaffFrom,
      );

  @override
  Future<Result<void>> recordEntry(Map<String, dynamic> body) => _void(
        _api.post(ApiEndpoints.recurringCheckEntries,
            data: body, silent: true, allowQueue: false),
      );

  @override
  Future<Result<List<CheckOption>>> residences() => _get(
        ApiEndpoints.residences,
        {'page': 1, 'limit': 100},
        RecurringChecksMapper.residencesFrom,
      );

  @override
  Future<Result<List<CheckOption>>> staff() => _get(
        ApiEndpoints.staff,
        {'page': 1, 'limit': 100},
        RecurringChecksMapper.peopleFrom,
      );

  @override
  Future<Result<List<CheckOption>>> clients({String? residenceId}) => _get(
        ApiEndpoints.clients,
        {'residenceId': ?residenceId, 'page': 1, 'limit': 100},
        RecurringChecksMapper.peopleFrom,
      );

  @override
  Future<Result<List<CheckOption>>> colleagues(String? residenceId) => _get(
        ApiEndpoints.staffDirectory,
        {'residenceId': ?residenceId},
        (body) => RecurringChecksMapper.peopleFrom(body, empty: 'Unnamed'),
      );

  @override
  Future<Result<String?>> openAttendanceResidenceId() {
    final now = DateTime.now().toUtc();
    return _get(
      ApiEndpoints.attendance,
      {
        'mine': true,
        'from': now.subtract(const Duration(hours: 48)).toIso8601String(),
        'to': now.add(const Duration(hours: 1)).toIso8601String(),
        'limit': 50,
      },
      RecurringChecksMapper.openAttendanceResidence,
    );
  }
}
