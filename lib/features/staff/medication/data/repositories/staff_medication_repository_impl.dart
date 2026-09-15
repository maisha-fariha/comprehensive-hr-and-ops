import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_client_medication_item.dart';
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
    final residenceId = _session.residenceId?.trim();
    if (residenceId == null || residenceId.isEmpty) {
      return Result.failure(
        const ApiError(
          message:
              'No residence is selected for this account. Choose a residence, then open Medication MAR again.',
        ),
      );
    }

    final result = await _api.get(
      ApiEndpoints.marRound,
      query: {
        'date': IsoDateRange.todayDate,
        'residenceId': residenceId,
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
    String? notes,
    bool isPrn = false,
  }) async {
    final staffId = _session.staffId?.trim();
    final data = <String, dynamic>{
      'source': isPrn ? 'prn' : 'prescribed',
      'clientId': clientId,
      'residenceId': residenceId,
      'status': status,
      'administeredAt': IsoDateRange.nowIso,
      if (isPrn)
        'prnMedicationId': medicationId
      else
        'medicationId': medicationId,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final result = await _api.post(
      ApiEndpoints.marAdministrations,
      data: data,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> getClientMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.medications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffMedicationMapper.clientMedicationsFrom(body, isPrn: false),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.prnMedications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffMedicationMapper.clientMedicationsFrom(body, isPrn: true),
      ),
      failure: (error) async => Result.failure(error),
    );
  }
}
