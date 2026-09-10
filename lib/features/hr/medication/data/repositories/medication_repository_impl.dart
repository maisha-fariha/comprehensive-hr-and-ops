import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/client_medication_item.dart';
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
    final resolved = await _resolveResidence();
    final residenceId = resolved.$1;
    final residenceName = resolved.$2 ?? _session.residenceName;

    if (residenceId == null || residenceId.isEmpty) {
      return Result.failure(
        const ApiError(
          message:
              'No residence is selected for this account. Choose a residence, then open Medication again.',
        ),
      );
    }

    final dueQuery = <String, dynamic>{
      'date': IsoDateRange.todayDate,
      'residenceId': residenceId,
    };

    final dayScoped = <String, dynamic>{
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'residenceId': residenceId,
    };

    final seriesQuery = <String, dynamic>{
      'metric': 'mar',
      'from': IsoDateRange.todayStartIso,
      'to': IsoDateRange.todayEndIso,
      'residenceId': residenceId,
    };

    // Overview + Due tab loads (all silent — page owns error UI):
    // - GET /mar/due (Due Today + Priority/Later/Completed)
    // - GET /mar/round (Morning/Afternoon/Evening)
    // - GET /mar/administrations missed|refused
    // - GET /reports/series?metric=mar
    final results = await Future.wait([
      _api.get(ApiEndpoints.marDue, query: dueQuery, silent: true),
      _api.get(ApiEndpoints.marRound, query: dueQuery, silent: true),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'missed', ...dayScoped},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.marAdministrations,
        query: {'status': 'refused', ...dayScoped},
        silent: true,
      ),
      _api.get(
        ApiEndpoints.reportsSeries,
        query: seriesQuery,
        silent: true,
      ),
    ]);

    final due = results[0];
    if (due.isFailure) {
      return Result.failure(
        due.error ??
            const ApiError(
              message:
                  'Could not load doses due for today. Check residence access and try again.',
            ),
      );
    }

    return Result.success(
      MedicationMapper.compose(
        dueBody: due.value,
        roundBody: results[1].isSuccess ? results[1].value : null,
        missedBody: results[2].isSuccess ? results[2].value : null,
        refusedBody: results[3].isSuccess ? results[3].value : null,
        seriesBody: results[4].isSuccess ? results[4].value : null,
        residenceName: residenceName,
      ),
    );
  }

  @override
  Future<Result<List<ClientMedicationItem>>> getClientMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.medications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        MedicationMapper.clientMedicationsFrom(body, isPrn: false),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ClientMedicationItem>>> getClientPrnMedications(
    String clientId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.prnMedications,
      query: {'clientId': clientId, 'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        MedicationMapper.clientMedicationsFrom(body, isPrn: true),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reviewMedicationIssue({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
    String severity = 'medium',
  }) async {
    final id = administrationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing administration id.'),
      );
    }

    final resolvedResidence =
        (residenceId?.trim().isNotEmpty ?? false)
            ? residenceId!.trim()
            : (await _resolveResidence()).$1;

    final result = await _api.post(
      ApiEndpoints.complianceFindings,
      data: {
        'sourceType': 'mar_administration',
        'sourceId': id,
        'title': title.trim(),
        'description': description.trim(),
        'severity': severity,
        if (resolvedResidence != null && resolvedResidence.isNotEmpty)
          'residenceId': resolvedResidence,
        if (clientId != null && clientId.trim().isNotEmpty)
          'clientId': clientId.trim(),
      },
      silent: true,
      allowQueue: false,
    );

    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> logMedicationFollowUp({
    required String administrationId,
    required String title,
    required String description,
    String? clientId,
    String? residenceId,
  }) async {
    final id = administrationId.trim();
    if (id.isEmpty) {
      return Result.failure(
        const ValidationError(message: 'Missing administration id.'),
      );
    }

    final resolvedResidence =
        (residenceId?.trim().isNotEmpty ?? false)
            ? residenceId!.trim()
            : (await _resolveResidence()).$1;

    final payload = <String, dynamic>{
      'sourceType': 'mar_administration',
      'sourceId': id,
      'title': title.trim(),
      'description': description.trim(),
      'status': 'open',
      if (resolvedResidence != null && resolvedResidence.isNotEmpty)
        'residenceId': resolvedResidence,
      if (clientId != null && clientId.trim().isNotEmpty)
        'clientId': clientId.trim(),
    };

    final corrective = await _api.post(
      ApiEndpoints.complianceCorrectiveActions,
      data: payload,
      silent: true,
      allowQueue: false,
    );
    if (corrective.isSuccess) {
      return Result.success(null);
    }

    // Residence Manager often lacks compliance:write — fall back to a task.
    final task = await _api.post(
      ApiEndpoints.tasks,
      data: {
        'taskType': 'care',
        'title': title.trim(),
        'description': description.trim(),
        'priority': 'medium',
        'status': 'open',
        'requiresReview': false,
        if (resolvedResidence != null && resolvedResidence.isNotEmpty)
          'residenceId': resolvedResidence,
        if (clientId != null && clientId.trim().isNotEmpty)
          'clientId': clientId.trim(),
      },
      silent: true,
      allowQueue: false,
    );

    return task.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(
        corrective.error ?? error,
      ),
    );
  }

  Future<(String?, String?)> _resolveResidence() async {
    final sessionId = _session.residenceId?.trim();
    final sessionName = _session.residenceName?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      return (sessionId, sessionName);
    }

    final result = await _api.get(
      ApiEndpoints.residences,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (result.isFailure) return (null, null);

    final rows = JsonCodec.unwrapList(result.value);
    for (final row in rows) {
      if (row is! Map) continue;
      final map = JsonCodec.asMap(row);
      final id = JsonCodec.string(map['id'] ?? map['residenceId'])?.trim();
      if (id == null || id.isEmpty) continue;
      final name = JsonCodec.string(map['name'] ?? map['residenceName']);
      _session.applyStaffContext(residenceId: id, residenceName: name);
      return (id, name);
    }
    return (null, null);
  }
}
