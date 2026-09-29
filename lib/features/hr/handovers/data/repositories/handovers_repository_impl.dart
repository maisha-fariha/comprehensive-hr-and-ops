import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/handover_options.dart';
import '../../domain/entities/shift_handover.dart';
import '../../domain/repositories/handovers_repository.dart';
import '../mappers/handovers_mapper.dart';

class HandoversRepositoryImpl implements HandoversRepository {
  final AppApiClient _api;

  HandoversRepositoryImpl({required AppApiClient api}) : _api = api;

  static const int _optionsLimit = 100;
  static const Duration _recentWindow = Duration(hours: 24);
  static const Duration _recentLead = Duration(hours: 2);

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

  Future<Result<void>> _post(String path, Map<String, dynamic> data) async {
    final result = await _api.post(path, data: data, silent: true, allowQueue: false);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ShiftHandover>>> list({
    String? status,
    String? staffId,
    String? residenceId,
    String? from,
    String? to,
  }) =>
      _get(
        ApiEndpoints.shiftHandovers,
        {
          'page': 1,
          'limit': 20,
          'residenceId': ?residenceId,
          'status': ?status,
          'from': ?from,
          'to': ?to,
          'staffId': ?staffId,
        },
        HandoversMapper.listFrom,
        silent: false,
      );

  @override
  Future<Result<ShiftHandover>> byId(String id) async {
    final result = await _api.get(ApiEndpoints.handoverById(id), silent: true);
    return result.when(
      success: (body) async {
        final handover = HandoversMapper.handoverFrom(JsonCodec.unwrapMap(body));
        return handover == null
            ? Result.failure(const ApiError(message: 'Handover could not be read'))
            : Result.success(handover);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<HandoverAnnouncement?>> create(Map<String, dynamic> body) async {
    final result = await _api.post(
      ApiEndpoints.shiftHandovers,
      data: body,
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (response) async =>
          Result.success(HandoversMapper.announcementFrom(response)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> setStatus(String id, String status) =>
      _post(ApiEndpoints.handoverStatus(id), {'status': status});

  @override
  Future<Result<void>> comment(String id, String body) =>
      _post(ApiEndpoints.handoverComments(id), {'body': body});

  @override
  Future<Result<void>> acknowledge(String id, {String? note}) =>
      _post(ApiEndpoints.handoverAcknowledge(id), {'note': ?note});

  @override
  Future<Result<void>> delete(String id) async {
    final result = await _api.delete(
      ApiEndpoints.handoverById(id),
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<HandoverOption>>> residences() => _get(
        ApiEndpoints.residences,
        {'page': 1, 'limit': _optionsLimit},
        HandoversMapper.residencesFrom,
      );

  @override
  Future<Result<List<HandoverOption>>> staff() => _get(
        ApiEndpoints.staff,
        {'page': 1, 'limit': _optionsLimit},
        HandoversMapper.staffFrom,
      );

  @override
  Future<Result<List<HandoverOption>>> clients(String residenceId) => _get(
        ApiEndpoints.clients,
        {'residenceId': residenceId, 'limit': _optionsLimit},
        HandoversMapper.clientsFrom,
      );

  ({String from, String to}) _recentRange() {
    final now = DateTime.now().toUtc();
    return (
      from: now.subtract(_recentWindow).toIso8601String(),
      to: now.add(_recentLead).toIso8601String(),
    );
  }

  static int _newestFirst(HandoverShift a, HandoverShift b) {
    final x = a.startsAt, y = b.startsAt;
    if (x == null || y == null) return 0;
    return y.compareTo(x);
  }

  @override
  Future<Result<List<HandoverShift>>> myRecentShifts(String staffId) async {
    final range = _recentRange();
    final shiftsRequest = _get(
      ApiEndpoints.shifts,
      {'staffId': staffId, 'limit': 20, 'from': range.from, 'to': range.to},
      HandoversMapper.shiftsFrom,
    );
    final attendanceRequest = _get(
      ApiEndpoints.attendance,
      {'mine': true, 'from': range.from, 'to': range.to, 'limit': 50},
      HandoversMapper.clockedInShiftIds,
    );
    final shifts = await shiftsRequest;
    final clockedIn = await attendanceRequest;
    if (shifts.isFailure) return Result.failure(shifts.error!);
    if (clockedIn.isFailure) return Result.failure(clockedIn.error!);
    final worked = clockedIn.value!;
    return Result.success(
      shifts.value!
          .where((s) => s.staff.any((p) => p.id == staffId && p.rostered))
          .where((s) => worked.contains(s.id))
          .toList()
        ..sort(_newestFirst),
    );
  }

  @override
  Future<Result<List<HandoverShift>>> residenceRecentShifts(String residenceId) {
    final range = _recentRange();
    return _get(
      ApiEndpoints.shifts,
      {'residenceId': residenceId, 'limit': 30, 'from': range.from, 'to': range.to},
      (body) => HandoversMapper.shiftsFrom(body)..sort(_newestFirst),
    );
  }

  @override
  Future<Result<List<HandoverShift>>> incomingShifts(
    String residenceId,
    DateTime? after,
  ) {
    final start = (after ?? DateTime.now()).toUtc();
    return _get(
      ApiEndpoints.shifts,
      {
        'residenceId': residenceId,
        'limit': 20,
        'from': start.toIso8601String(),
        'to': start.add(const Duration(hours: 48)).toIso8601String(),
      },
      (body) {
        final shifts = HandoversMapper.shiftsFrom(body)
            .where((s) => s.startsAt != null && !s.startsAt!.isBefore(start))
            .toList()
          ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
        return shifts.take(10).toList();
      },
    );
  }
}
