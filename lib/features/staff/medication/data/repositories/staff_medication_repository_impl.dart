import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import '../mappers/staff_medication_mapper.dart';

class StaffMedicationRepositoryImpl implements StaffMedicationRepository {
  final AppApiClient _api;
  final UserSession _session;

  /// Optional user-selected residence filter (overrides session when set).
  String? selectedResidenceId;

  StaffMedicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffMedicationOverview>> getOverview({
    String? residenceId,
  }) async {
    final filter = (residenceId ?? selectedResidenceId ?? _session.residenceId)
        ?.trim();

    final result = await _api.get(
      ApiEndpoints.marRound,
      query: {
        'date': IsoDateRange.todayDate,
        // Staff accounts often have no default residence; API allows omit
        // (web "across all residences").
        if (filter != null && filter.isNotEmpty) 'residenceId': filter,
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
    String? clinicalNotes,
    String? doseReason,
    String? witnessStaffId,
    bool isPrn = false,
    Map<String, bool>? safetyChecks,
    Map<String, String>? vitals,
  }) async {
    final staffId = _session.staffId?.trim();
    final cleanedVitals = <String, String>{};
    if (vitals != null) {
      for (final entry in vitals.entries) {
        final value = entry.value.trim();
        if (value.isNotEmpty) cleanedVitals[entry.key] = value;
      }
    }
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
      if (clinicalNotes != null && clinicalNotes.trim().isNotEmpty)
        'clinicalNotes': clinicalNotes.trim(),
      if (doseReason != null && doseReason.trim().isNotEmpty)
        'doseReason': doseReason.trim(),
      if (witnessStaffId != null && witnessStaffId.trim().isNotEmpty)
        'witnessStaffId': witnessStaffId.trim(),
      if (safetyChecks != null && safetyChecks.isNotEmpty)
        'safetyChecks': safetyChecks,
      if (cleanedVitals.isNotEmpty) 'vitals': cleanedVitals,
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

  @override
  Future<Result<List<StaffClientMedicationItem>>> listPrnMedications({
    String? residenceId,
  }) async {
    final filter = (residenceId ?? selectedResidenceId ?? _session.residenceId)
        ?.trim();
    final result = await _api.get(
      ApiEndpoints.prnMedications,
      query: {
        'page': 1,
        'limit': 100,
        if (filter != null && filter.isNotEmpty) 'residenceId': filter,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items =
            StaffMedicationMapper.clientMedicationsFrom(body, isPrn: true);
        return Result.success(await _enrichMedicationResidences(items));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<AdministeredDose>>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  }) async {
    final filter = (residenceId ?? selectedResidenceId ?? _session.residenceId)
        ?.trim();
    final result = await _api.get(
      ApiEndpoints.marAdministrations,
      query: {
        'page': page,
        'limit': limit,
        if (filter != null && filter.isNotEmpty) 'residenceId': filter,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final residences = await _residenceNameMap();
        final items = <AdministeredDose>[];
        for (final row in JsonCodec.unwrapList(body)) {
          if (row is! Map) continue;
          final json = JsonCodec.asMap(row);
          final mapped = StaffMedicationMapper.administrationsFrom([json]).first;
          final rid = JsonCodec.string(json['residenceId']);
          items.add(
            AdministeredDose(
              id: mapped.id,
              residentName: mapped.residentName,
              residentInitials: mapped.residentInitials,
              avatarColor: mapped.avatarColor,
              medicationName: mapped.medicationName,
              dose: mapped.dose,
              route: mapped.route,
              givenTimeLabel: mapped.givenTimeLabel,
              administeredByName: mapped.administeredByName,
              outcomeLabel: mapped.outcomeLabel,
              residenceName: mapped.residenceName.isNotEmpty
                  ? mapped.residenceName
                  : (rid == null ? '' : (residences[rid] ?? '')),
            ),
          );
        }
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.medications,
      query: {
        'page': 1,
        'limit': 100,
        if (residenceId != null && residenceId.isNotEmpty)
          'residenceId': residenceId,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items =
            StaffMedicationMapper.clientMedicationsFrom(body, isPrn: false);
        return Result.success(await _enrichMedicationResidences(items));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Future<Map<String, String>> _residenceNameMap() async {
    final result = await getResidences();
    final map = <String, String>{};
    result.when(
      success: (list) {
        for (final r in list) {
          map[r.id] = r.name;
        }
      },
      failure: (_) {},
    );
    return map;
  }

  Future<List<StaffClientMedicationItem>> _enrichMedicationResidences(
    List<StaffClientMedicationItem> items,
  ) async {
    if (items.every((i) => i.residenceName.isNotEmpty)) return items;
    final names = await _residenceNameMap();
    // Also try to fill client names from clients list when missing.
    final clients = await getClients();
    final clientNames = <String, String>{};
    clients.when(
      success: (list) {
        for (final c in list) {
          clientNames[c.id] = c.name;
          if (c.residenceId != null &&
              c.residenceId!.isNotEmpty &&
              c.residenceName != null &&
              c.residenceName!.isNotEmpty) {
            names.putIfAbsent(c.residenceId!, () => c.residenceName!);
          }
        }
      },
      failure: (_) {},
    );
    return [
      for (final item in items)
        StaffClientMedicationItem(
          id: item.id,
          name: item.name,
          dose: item.dose,
          scheduleLabel: item.scheduleLabel,
          instructions: item.instructions,
          isPrn: item.isPrn,
          clientId: item.clientId,
          clientName: item.clientName.isNotEmpty
              ? item.clientName
              : (clientNames[item.clientId] ?? ''),
          residenceId: item.residenceId,
          residenceName: item.residenceName.isNotEmpty
              ? item.residenceName
              : (names[item.residenceId] ?? ''),
        ),
    ];
  }

  @override
  Future<Result<void>> createMedication(StaffCreateMedicationInput input) async {
    final data = <String, dynamic>{
      'residenceId': input.residenceId,
      'clientId': input.clientId,
      'name': input.name.trim(),
      if (input.dose != null && input.dose!.trim().isNotEmpty)
        'dose': input.dose!.trim(),
      if (input.route != null && input.route!.trim().isNotEmpty)
        'route': input.route!.trim(),
      if (input.stockUnitsPerDose != null)
        'stockUnitsPerDose': input.stockUnitsPerDose,
      'schedule': {
        'frequency': input.scheduleFrequency,
        if (input.scheduleTimes.isNotEmpty) 'times': input.scheduleTimes,
      },
      'scheduleFrequency': input.scheduleFrequency,
      if (input.scheduleTimes.isNotEmpty) 'scheduleTimes': input.scheduleTimes,
      if (input.startsAt != null)
        'startsAt': input.startsAt!.toUtc().toIso8601String(),
      if (input.endsAt != null)
        'endsAt': input.endsAt!.toUtc().toIso8601String(),
      'isControlled': input.isControlled,
    };
    final result = await _api.post(ApiEndpoints.medications, data: data);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createPrnMedication(
    StaffCreatePrnMedicationInput input,
  ) async {
    final data = <String, dynamic>{
      'residenceId': input.residenceId,
      if (input.clientId != null && input.clientId!.trim().isNotEmpty)
        'clientId': input.clientId!.trim(),
      'name': input.name.trim(),
      if (input.dose != null && input.dose!.trim().isNotEmpty)
        'dose': input.dose!.trim(),
      if (input.route != null && input.route!.trim().isNotEmpty)
        'route': input.route!.trim(),
      if (input.instructions != null && input.instructions!.trim().isNotEmpty)
        'instructions': input.instructions!.trim(),
      if (input.stockUnitsPerDose != null)
        'stockUnitsPerDose': input.stockUnitsPerDose,
      if (input.startsAt != null)
        'startsAt': input.startsAt!.toUtc().toIso8601String(),
      if (input.endsAt != null)
        'endsAt': input.endsAt!.toUtc().toIso8601String(),
      'isControlled': input.isControlled,
    };
    final result = await _api.post(ApiEndpoints.prnMedications, data: data);
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffMedResidenceOption>>> getResidences() async {
    final result = await _api.get(ApiEndpoints.residences, silent: true);
    return result.when(
      success: (body) async {
        final list = JsonCodec.unwrapList(body);
        final options = <StaffMedResidenceOption>[];
        for (final item in list) {
          if (item is! Map) continue;
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          final name = JsonCodec.string(json['name'] ?? json['title']);
          if (id == null || id.isEmpty || name == null || name.isEmpty) {
            continue;
          }
          options.add(StaffMedResidenceOption(id: id, name: name));
        }
        return Result.success(options);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffMedClientOption>>> getClients({
    String? residenceId,
    String? search,
  }) async {
    final trimmed = search?.trim();
    final hasResidence = residenceId != null && residenceId.isNotEmpty;
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'page': 1,
        'limit': 100,
        if (hasResidence) 'residenceId': residenceId,
        if (trimmed != null && trimmed.isNotEmpty) 'search': trimmed,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final list = JsonCodec.unwrapList(body);
        final options = <StaffMedClientOption>[];
        for (final item in list) {
          if (item is! Map) continue;
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          final first = JsonCodec.stringOr(json['firstName'], '');
          final last = JsonCodec.stringOr(json['lastName'], '');
          final composed = '$first $last'.trim();
          final name = JsonCodec.string(
                json['preferredName'] ??
                    json['name'] ??
                    json['fullName'] ??
                    (composed.isEmpty ? null : composed),
              ) ??
              '';
          if (id == null || id.isEmpty || name.isEmpty) continue;
          final residence = JsonCodec.mapAt(json, 'residence');
          options.add(
            StaffMedClientOption(
              id: id,
              name: name,
              residenceId: JsonCodec.string(
                json['residenceId'] ?? residence?['id'],
              ),
              residenceName: JsonCodec.string(
                json['residenceName'] ?? residence?['name'],
              ),
            ),
          );
        }
        return Result.success(options);
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
