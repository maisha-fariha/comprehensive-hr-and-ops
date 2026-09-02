import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/medication_overview.dart';
import '../../domain/repositories/medication_repository.dart';
import '../mappers/medication_mapper.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final AppApiClient _api;
  final UserSession _session;

  MedicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<MedicationOverview>> getOverview() async {
    final residenceId = _session.residenceId;
    final query = <String, dynamic>{
      'residenceId': ?residenceId,
    };
    final due = await _api.get(ApiEndpoints.marDue, query: query);
    if (due.isFailure) {
      return Result.failure(
        due.error ?? const ApiError(message: 'Could not load medications.'),
      );
    }
    final extras = await Future.wait([
      _api.get(ApiEndpoints.marRound, query: query),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'missed', 'residenceId': ?residenceId},
      ),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'refused', 'residenceId': ?residenceId},
      ),
    ]);
    return Result.success(
      MedicationMapper.compose(
        dueBody: due.value,
        roundBody: extras[0].value,
        missedBody: extras[1].value,
        refusedBody: extras[2].value,
        residenceName: _session.residenceName,
      ),
    );
  }
}
