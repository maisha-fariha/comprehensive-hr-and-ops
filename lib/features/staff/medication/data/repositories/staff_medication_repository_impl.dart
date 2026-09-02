import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import '../mappers/staff_medication_mapper.dart';

class StaffMedicationRepositoryImpl implements StaffMedicationRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffMedicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffMedicationOverview>> getOverview() async {
    final result = await _api.get(
      ApiEndpoints.marRound,
      query: {
        'date': IsoDateRange.todayDate,
        'residenceId': ?_session.residenceId,
      },
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffMedicationMapper.fromRound(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordAdministration({
    required String clientId,
    required String residenceId,
    required String medicationId,
    required String status,
  }) async {
    final result = await _api.post(
      ApiEndpoints.marAdministrations,
      data: {
        'clientId': clientId,
        'residenceId': residenceId,
        'medicationId': medicationId,
        'status': status,
        'administeredAt': IsoDateRange.nowIso,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
