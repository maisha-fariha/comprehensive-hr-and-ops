import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../mappers/emergency_mapper.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final AppApiClient _api;

  EmergencyRepositoryImpl({required AppApiClient api}) : _api = api;

  static Result<void> _done(Result<dynamic> result) => result.when(
        success: (_) => Result.success(null),
        failure: Result.failure,
      );

  Future<Result<void>> _post(String path, Map<String, dynamic> data) async =>
      _done(await _api.post(path, data: data, silent: true, allowQueue: false));

  @override
  Future<Result<EmergencyAlertPage>> list({
    String? status,
    required int page,
    required int limit,
  }) async {
    final result = await _api.get(
      ApiEndpoints.emergencyAlerts,
      query: {'status': ?status, 'page': page, 'limit': limit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(EmergencyMapper.pageFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<EmergencyAlert>> byId(String id) async {
    final result =
        await _api.get(ApiEndpoints.emergencyAlertById(id), silent: true);
    return result.when(
      success: (body) {
        final alert = EmergencyMapper.alertFrom(JsonCodec.unwrapMap(body));
        return alert == null
            ? Result.failure(const ApiError(message: 'Alarm could not be read'))
            : Result.success(alert);
      },
      failure: Result.failure,
    );
  }

  @override
  Future<Result<void>> raise({
    required String residenceId,
    required String type,
    String? note,
    String? locationNote,
    double? latitude,
    double? longitude,
  }) =>
      _post(ApiEndpoints.emergencyAlerts, {
        'residenceId': residenceId,
        'type': type,
        'note': ?note,
        'locationNote': ?locationNote,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });

  @override
  Future<Result<void>> acknowledge(String id) =>
      _post(ApiEndpoints.emergencyAlertAcknowledge(id), const {});

  @override
  Future<Result<void>> resolve(String id) =>
      _post(ApiEndpoints.emergencyAlertResolve(id), const {});

  @override
  Future<Result<void>> assign(String id, String userId) =>
      _post(ApiEndpoints.emergencyAlertAssign(id), {'assignedTo': userId});

  @override
  Future<Result<void>> setStatus(String id, String status) async => _done(
        await _api.patch(
          ApiEndpoints.emergencyAlertStatus(id),
          data: {'status': status},
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> addNote(String id, String note) =>
      _post(ApiEndpoints.emergencyAlertNotes(id), {'note': note});

  @override
  Future<Result<void>> delete(String id) async => _done(
        await _api.delete(
          ApiEndpoints.emergencyAlertById(id),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<List<EmergencyOption>>> residences() async {
    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(EmergencyMapper.residencesFrom(body)),
      failure: Result.failure,
    );
  }
}
