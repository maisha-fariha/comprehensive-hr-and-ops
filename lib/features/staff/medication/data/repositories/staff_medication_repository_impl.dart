import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../hr/medication/data/mappers/medication_mapper.dart';
import '../../../../hr/medication/domain/entities/mar_medication_stock.dart';
import '../../../../hr/medication/domain/entities/mar_round.dart';
import '../../domain/entities/administered_dose.dart';
import '../../domain/entities/staff_client_medication_item.dart';
import '../../domain/entities/staff_med_options.dart';
import '../../domain/entities/staff_medication_overview.dart';
import '../../domain/repositories/staff_medication_repository.dart';
import '../mappers/staff_medication_mapper.dart';

class StaffMedicationRepositoryImpl implements StaffMedicationRepository {
  final AppApiClient _api;
  final UserSession _session;

  /// Optional user-selected residence filter.
  String? selectedResidenceId;

  StaffMedicationRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  /// The web scopes the round and PRN register only by the registry's
  /// residence filter; a session default would hide rows the web shows.
  String? _residenceFilter(String? residenceId) {
    final filter = (residenceId ?? selectedResidenceId)?.trim();
    return filter == null || filter.isEmpty ? null : filter;
  }

  @override
  Future<Result<StaffMedicationOverview>> getOverview({
    String? residenceId,
  }) async {
    final filter = _residenceFilter(residenceId);

    // No `date`: the server's own "today", as the web asks for it.
    final result = await _api.get(
      ApiEndpoints.marRound,
      query: {
        'residenceId': ?filter,
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
    DateTime? scheduledFor,
    bool scheduled = true,
    Map<String, bool>? safetyChecks,
    Map<String, String>? vitals,
  }) async {
    // Web charts via `POST /mar/administrations/round` (not a bare
    // `/mar/administrations` create). Using the create path duplicates
    // Given rows and can 403 approved-staff checks differently.
    final staffId = _session.staffId?.trim() ?? '';
    if (staffId.isEmpty) {
      return Result.failure(
        const ApiError(
          message: 'Say who administered it — your staff profile is missing.',
        ),
      );
    }
    final cleanedVitals = <String, String>{};
    if (vitals != null) {
      for (final entry in vitals.entries) {
        final value = entry.value.trim();
        if (value.isNotEmpty) cleanedVitals[entry.key] = value;
      }
    }
    final anyCheck =
        safetyChecks != null && safetyChecks.values.any((v) => v);
    final reason = doseReason?.trim() ?? '';
    // Web: for prescribed round doses, send occurrence dueAt as
    // `scheduledFor` so the API charts that slot (not another already-given
    // time for the same medicine).
    final scheduledForIso = (!isPrn &&
            scheduled &&
            scheduledFor != null)
        ? scheduledFor.toUtc().toIso8601String()
        : null;
    final item = <String, dynamic>{
      'source': isPrn ? 'prn' : 'prescribed',
      if (isPrn) 'prnMedicationId': medicationId else 'medicationId': medicationId,
      'status': status,
      if (status != 'administered' && reason.isNotEmpty) 'reason': reason,
      if (scheduledForIso != null) 'scheduledFor': scheduledForIso,
      if (witnessStaffId != null && witnessStaffId.trim().isNotEmpty)
        'witnessStaffId': witnessStaffId.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (clinicalNotes != null && clinicalNotes.trim().isNotEmpty)
        'clinicalNotes': clinicalNotes.trim(),
      if (status == 'administered' && anyCheck) 'safetyChecks': safetyChecks,
      if (status == 'administered' && cleanedVitals.isNotEmpty)
        'vitals': cleanedVitals,
    };
    final data = <String, dynamic>{
      'clientId': clientId,
      'residenceId': residenceId,
      'staffId': staffId,
      'administeredAt': IsoDateRange.nowIso,
      'items': [item],
    };

    final result = await _api.post(
      ApiEndpoints.marAdministrationRound,
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
    final filter = _residenceFilter(residenceId);
    final result = await _api.get(
      ApiEndpoints.prnMedications,
      query: {
        'page': 1,
        'limit': 100,
        'residenceId': ?filter,
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
  Future<Result<MarAdministrationsList>> listAdministrations({
    String? residenceId,
    int page = 1,
    int limit = 50,
  }) async {
    // Web Given tab: every page, no status filter; badge = meta.total.
    final filter = residenceId?.trim();
    final residences = await _residenceNameMap();
    final items = <AdministeredDose>[];
    var current = page;
    var totalPages = 1;
    int? badgeTotal;
    do {
      final result = await _api.get(
        ApiEndpoints.marAdministrations,
        query: {
          'page': current,
          'limit': limit < 100 ? 100 : limit,
          if (filter != null && filter.isNotEmpty) 'residenceId': filter,
        },
        silent: true,
      );
      if (result.isFailure) {
        return Result.failure(
          result.error ??
              const ApiError(message: 'Could not load charted doses.'),
        );
      }
      final meta = JsonCodec.metaOf(result.value);
      badgeTotal ??= JsonCodec.integer(meta?['total']);
      for (final row in JsonCodec.unwrapList(result.value)) {
        if (row is! Map) continue;
        final json = JsonCodec.asMap(row);
        final mapped = StaffMedicationMapper.administrationsFrom([json]).first;
        final rid = JsonCodec.string(json['residenceId']);
        final house = mapped.residenceName.isNotEmpty
            ? mapped.residenceName
            : (rid == null ? '' : (residences[rid] ?? ''));
        items.add(
          house == mapped.residenceName
              ? mapped
              : mapped.copyWith(residenceName: house),
        );
      }
      totalPages = JsonCodec.integerOr(meta?['totalPages'], 1);
      current++;
    } while (current <= totalPages && current <= 50);
    return Result.success(
      MarAdministrationsList(
        items: items,
        total: badgeTotal ?? items.length,
      ),
    );
  }

  @override
  Future<Result<List<StaffClientMedicationItem>>> listMedications({
    String? residenceId,
    String? clientId,
    String? type,
  }) async {
    final result = await _api.get(
      ApiEndpoints.medications,
      query: {
        'page': 1,
        'limit': 100,
        if (residenceId != null && residenceId.isNotEmpty)
          'residenceId': residenceId,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
        if (type != null && type.isNotEmpty) 'type': type,
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

  @override
  Future<Result<List<MarMedicationStock>>> listMedicationStock({
    String? residenceId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.medicationStock,
      query: {
        'page': 1,
        'limit': 100,
        if (residenceId != null && residenceId.isNotEmpty)
          'residenceId': residenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(MedicationMapper.stocksFrom(body)),
      failure: Result.failure,
    );
  }

  @override
  Future<Result<MarMedicationStock>> setMedicationStock(
    MarStockCountDraft draft,
  ) async {
    final result = await _api.put(
      ApiEndpoints.medicationStock,
      data: MedicationMapper.stockCountToJson(draft),
      silent: true,
      allowQueue: false,
    );
    return result.when(
      success: (body) {
        final map = JsonCodec.mapAt(body, 'data') ??
            (body is Map ? JsonCodec.asMap(body) : null);
        if (map == null) {
          return Result.failure(
            const ApiError(message: 'Stock count response was empty.'),
          );
        }
        return Result.success(MedicationMapper.stockFrom(map));
      },
      failure: Result.failure,
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
        item.copyWith(
          clientName: item.clientName.isNotEmpty
              ? item.clientName
              : (clientNames[item.clientId] ?? ''),
          residenceName: item.residenceName.isNotEmpty
              ? item.residenceName
              : (names[item.residenceId] ?? ''),
        ),
    ];
  }

  /// The web sends the picked calendar day as UTC midnight.
  static String? _day(DateTime? value) => value == null
      ? null
      : DateTime.utc(value.year, value.month, value.day).toIso8601String();

  /// End of that calendar day. A same-day course must end after its start
  /// midnight — the API rejects an end that is not later.
  static String? _endOfDay(DateTime? value) => value == null
      ? null
      : DateTime.utc(value.year, value.month, value.day, 23, 59, 59, 999)
          .toIso8601String();

  static String? _blank(String? value) {
    final t = value?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  /// The API rejects `route: null`: a blank route is left out of a create and
  /// sent as `''` on an update so a cleared route is saved.
  static String? _route(String? value, {required bool update}) =>
      update ? (value?.trim() ?? '') : _blank(value);

  Map<String, dynamic> _medicationBody(
    StaffCreateMedicationInput input, {
    required bool update,
  }) {
    final checkId = _blank(input.requiresCheckScheduleId);
    return {
      'residenceId': input.residenceId,
      'clientId': input.clientId,
      'name': input.name.trim(),
      'dose': ?_blank(input.dose),
      'route': ?_route(input.route, update: update),
      'schedule': {
        'frequency': input.scheduleFrequency,
        if (input.scheduleTimes.isNotEmpty) 'times': input.scheduleTimes,
        if (input.scheduleFrequency == 'weekly')
          'weekdays': input.scheduleWeekdays,
      },
      'isControlled': input.isControlled,
      'startsAt': _day(input.startsAt),
      'endsAt': _endOfDay(input.endsAt),
      'stockUnitsPerDose': input.stockUnitsPerDose,
      'costPerDose': input.costPerDose,
      'requiresCheckScheduleId': checkId,
      'requiresCheckWithinMinutes': checkId == null
          ? null
          : ((input.requiresCheckWithinMinutes ?? 0) == 0
              ? 60
              : input.requiresCheckWithinMinutes),
    };
  }

  Map<String, dynamic> _prnBody(
    StaffCreatePrnMedicationInput input, {
    required bool update,
  }) {
    final checkId = _blank(input.requiresCheckScheduleId);
    return {
      'residenceId': input.residenceId,
      'name': input.name.trim(),
      'clientId': ?_blank(input.clientId),
      'dose': ?_blank(input.dose),
      'instructions': ?_blank(input.instructions),
      'isControlled': input.isControlled,
      'minIntervalMinutes': input.minIntervalMinutes,
      'stockUnitsPerDose': input.stockUnitsPerDose,
      'costPerDose': input.costPerDose,
      'route': ?_route(input.route, update: update),
      'startsAt': _day(input.startsAt),
      'endsAt': _endOfDay(input.endsAt),
      'requiresCheckScheduleId': checkId,
      'requiresCheckWithinMinutes': checkId == null
          ? null
          : ((input.requiresCheckWithinMinutes ?? 0) == 0
              ? 60
              : input.requiresCheckWithinMinutes),
    };
  }

  static Future<Result<void>> _done(Result<dynamic> result) => result.when(
        success: (_) async => Result.success(null),
        failure: (error) async => Result.failure(error),
      );

  @override
  Future<Result<void>> createMedication(StaffCreateMedicationInput input) async {
    return _done(
      await _api.post(
        ApiEndpoints.medications,
        data: _medicationBody(input, update: false),
      ),
    );
  }

  @override
  Future<Result<void>> updateMedication(
    String id,
    StaffCreateMedicationInput input,
  ) async {
    return _done(
      await _api.patch(
        '${ApiEndpoints.medications}/$id',
        data: _medicationBody(input, update: true),
      ),
    );
  }

  @override
  Future<Result<void>> createPrnMedication(
    StaffCreatePrnMedicationInput input,
  ) async {
    return _done(
      await _api.post(
        ApiEndpoints.prnMedications,
        data: _prnBody(input, update: false),
      ),
    );
  }

  @override
  Future<Result<void>> updatePrnMedication(
    String id,
    StaffCreatePrnMedicationInput input,
  ) async {
    return _done(
      await _api.patch(
        '${ApiEndpoints.prnMedications}/$id',
        data: _prnBody(input, update: true),
      ),
    );
  }

  @override
  Future<Result<void>> deleteMedication(String id) async => _done(
        await _api.delete(
          '${ApiEndpoints.medications}/$id',
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> discontinueMedication(String id) async => _done(
        await _api.post(
          '${ApiEndpoints.medications}/$id/discontinue',
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> deletePrnMedication(String id) async => _done(
        await _api.delete(
          '${ApiEndpoints.prnMedications}/$id',
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> discontinuePrnMedication(String id) async => _done(
        await _api.post(
          '${ApiEndpoints.prnMedications}/$id/discontinue',
          allowQueue: false,
        ),
      );

  @override
  Future<Result<MarResidentChart>> residentChart(String clientId) async {
    final result = await _api.get(
      ApiEndpoints.marResidentChart(clientId),
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(MedicationMapper.chartFrom(body)),
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

  @override
  Future<Result<List<StaffMedCheckOption>>> getCheckSchedules({
    String? residenceId,
  }) async {
    final hasResidence = residenceId != null && residenceId.isNotEmpty;
    final result = await _api.get(
      ApiEndpoints.recurringCheckSchedules,
      query: {
        'page': 1,
        'limit': 100,
        if (hasResidence) 'residenceId': residenceId,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final options = <StaffMedCheckOption>[];
        for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
          final json = JsonCodec.asMap(item);
          final id = JsonCodec.string(json['id']);
          final name = JsonCodec.string(
            json['name'] ?? json['title'] ?? json['checkType'],
          );
          if (id == null || id.isEmpty || name == null || name.isEmpty) {
            continue;
          }
          options.add(StaffMedCheckOption(id: id, name: name));
        }
        return Result.success(options);
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
