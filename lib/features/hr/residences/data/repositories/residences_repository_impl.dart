import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/config/app_env.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/network/tenant_store.dart';
import '../../../../../core/network/token_store.dart';
import '../../domain/entities/residence_detail_tabs.dart';
import '../../domain/entities/residence_form.dart';
import '../../domain/entities/residence_summary.dart';
import '../../domain/repositories/residences_repository.dart';
import '../mappers/residences_mapper.dart';
import '../residences_endpoints.dart';

class ResidencesRepositoryImpl
    implements ResidencesRepository, ResidenceAdminRepository {
  static const _pageSize = 100;
  static const _maxPages = 5;

  final AppApiClient _api;
  final TokenStore? _tokens;
  final TenantStore? _tenant;

  ResidencesRepositoryImpl({
    required AppApiClient api,
    TokenStore? tokens,
    TenantStore? tenant,
  })  : _api = api,
        _tokens = tokens,
        _tenant = tenant;

  @override
  Future<Result<List<ResidenceSummary>>> getResidences() async {
    final all = <ResidenceSummary>[];
    for (var page = 1; page <= _maxPages; page++) {
      final result = await listResidences(page: page, limit: _pageSize);
      if (result.isFailure) {
        return Result.failure(
          result.error ?? const ApiError(message: 'Could not load residences.'),
        );
      }
      final data = result.value!;
      all.addAll(data.items);
      if (page >= data.totalPages || data.items.length < _pageSize) break;
    }
    all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Result.success(all);
  }

  @override
  Future<Result<List<ResidenceRoom>>> getRooms(String residenceId) async {
    final result = await getRoomBoard(residenceId);
    return result.when(
      success: (board) => Result.success(board.rooms),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<ResidencesPageData>> listResidences({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? residenceType,
  }) async {
    final q = search?.trim();
    final result = await _api.get(
      ResidencesEndpoints.residences,
      query: {
        'page': page,
        'limit': limit,
        if (q != null && q.isNotEmpty) 'search': q,
        if (status != null && status.isNotEmpty) 'status': status,
        if (residenceType != null && residenceType.isNotEmpty)
          'residenceType': residenceType,
      },
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.pageFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<ResidenceSummary>> getResidence(String residenceId) async {
    final result = await _api.get(
      ResidencesEndpoints.residence(residenceId),
      silent: true,
    );
    return _residenceResult(result, 'Residence not found.');
  }

  @override
  Future<Result<ResidenceSummary>> createResidence(
    Map<String, dynamic> body,
    List<ResidenceAssignment> assignments,
  ) async {
    final created = await _api.post(
      ResidencesEndpoints.residences,
      data: body,
      silent: true,
      allowQueue: false,
    );
    final residence = _residenceResult(created, 'Failed to save residence');
    if (residence.isFailure || assignments.isEmpty) return residence;
    final assigned = await _replaceAssignments(residence.value!.id, assignments);
    if (assigned.isFailure) return Result.failure(assigned.error!);
    return residence;
  }

  @override
  Future<Result<ResidenceSummary>> updateResidence(
    String residenceId,
    Map<String, dynamic> body, {
    List<ResidenceAssignment>? assignments,
  }) async {
    final updated = await _api.patch(
      ResidencesEndpoints.residence(residenceId),
      data: body,
      silent: true,
      allowQueue: false,
    );
    final residence = _residenceResult(updated, 'Failed to save residence');
    if (residence.isFailure || assignments == null) return residence;
    final assigned = await _replaceAssignments(residenceId, assignments);
    if (assigned.isFailure) return Result.failure(assigned.error!);
    return getResidence(residenceId);
  }

  Future<Result<void>> _replaceAssignments(
    String residenceId,
    List<ResidenceAssignment> assignments,
  ) {
    return _send(
      _api.put(
        ResidencesEndpoints.assignments(residenceId),
        data: {
          'assignments': [
            for (final a in assignments) {'staffId': a.staffId, 'role': a.role},
          ],
        },
        silent: true,
        allowQueue: false,
      ),
    );
  }

  @override
  Future<Result<void>> setStatus(String residenceId, String status) => _send(
        _api.patch(
          ResidencesEndpoints.status(residenceId),
          data: {'status': status},
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> deleteResidence(String residenceId) => _send(
        _api.delete(
          ResidencesEndpoints.residence(residenceId),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> updatePayrollSettings(
    String residenceId, {
    required bool outOfPocketEnabled,
    required bool mileageEnabled,
  }) =>
      _send(
        _api.patch(
          ResidencesEndpoints.payrollSettings(residenceId),
          data: {
            'outOfPocketEnabled': outOfPocketEnabled,
            'mileageEnabled': mileageEnabled,
          },
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<ResidenceRoomBoard>> getRoomBoard(
    String residenceId, {
    bool includeArchived = false,
  }) async {
    final result = await _api.get(
      ResidencesEndpoints.rooms(residenceId),
      query: {if (includeArchived) 'includeArchived': true},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.roomBoardFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createRoom(
    String residenceId, {
    required String name,
    required int capacity,
    String? floor,
    String? wing,
    String? roomType,
  }) =>
      _send(
        _api.post(
          ResidencesEndpoints.rooms(residenceId),
          data: {
            'name': name,
            'capacity': capacity,
            'floor': ?floor,
            'wing': ?wing,
            'roomType': ?roomType,
          },
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> reactivateRoom(String residenceId, String roomId) =>
      _send(
        _api.patch(
          ResidencesEndpoints.room(residenceId, roomId),
          data: const {'isActive': true},
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<void>> archiveRoom(String residenceId, String roomId) => _send(
        _api.delete(
          ResidencesEndpoints.room(residenceId, roomId),
          silent: true,
          allowQueue: false,
        ),
      );

  @override
  Future<Result<ResidenceTabPage<ResidenceResident, ResidentsSummary>>>
      getResidents(
    String residenceId, {
    required int page,
    required int limit,
  }) async {
    final result = await _api.get(
      ResidencesEndpoints.clients,
      query: {'residenceId': residenceId, 'page': page, 'limit': limit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.residentsFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<ResidenceTabPage<ResidenceStaffMember, StaffSummary>>> getStaff(
    String residenceId, {
    required int page,
    required int limit,
  }) async {
    final result = await _api.get(
      ResidencesEndpoints.staff,
      query: {'residenceId': residenceId, 'page': page, 'limit': limit},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.staffFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ResidenceShift>>> getShifts(
    String residenceId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _api.get(
      ResidencesEndpoints.shifts,
      query: {
        'residenceId': residenceId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'page': 1,
        'limit': 200,
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.shiftsFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getReviewQueue(
    String residenceId, {
    required int page,
    required int limit,
  }) =>
      _logDays(residenceId, 'review', page, limit);

  @override
  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> getMissingLogs(
    String residenceId, {
    required int page,
    required int limit,
  }) =>
      _logDays(residenceId, 'missing', page, limit);

  Future<Result<ResidenceTabPage<ResidenceLogDay, void>>> _logDays(
    String residenceId,
    String status,
    int page,
    int limit,
  ) async {
    final result = await _api.get(
      ResidencesEndpoints.dailyLogs,
      query: {
        'residenceId': residenceId,
        'status': status,
        'page': page,
        'limit': limit,
      },
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.logDaysFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<List<ResidenceStaffOption>>> getStaffOptions() async {
    final result = await _api.get(
      ResidencesEndpoints.staff,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    return result.when(
      success: (body) => Result.success(ResidencesMapper.staffOptionsFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<ResidenceTenantContext>> getTenantContext() async {
    final result = await _api.get(ResidencesEndpoints.authMe, silent: true);
    return result.when(
      success: (body) =>
          Result.success(ResidencesMapper.tenantContextFrom(body)),
      failure: (error) => Result.failure(error),
    );
  }

  @override
  Future<Result<List<int>>> exportRoster() async {
    final server = await _tryServerRosterExport();
    if (server.isSuccess && (server.value?.isNotEmpty ?? false)) return server;
    if (server.error?.message == stillRunningMessage) return server;
    return _buildRosterCsv();
  }

  static const stillRunningMessage =
      'Export is still running — it will appear on the Reports page when it finishes.';

  /// Web `ExportButton`: `POST /reports/exports` (`residence_roster`), poll,
  /// then download. Roles that may create but not read exports fall back to
  /// [_buildRosterCsv].
  Future<Result<List<int>>> _tryServerRosterExport() async {
    final create = await _api.post(
      ResidencesEndpoints.reportsExports,
      data: const {'reportKey': 'residence_roster', 'format': 'csv'},
      silent: true,
      allowQueue: false,
    );
    if (create.isFailure) {
      return Result.failure(
        create.error ?? const ApiError(message: 'Could not create the export.'),
      );
    }
    final created = JsonCodec.unwrapMap(create.value);
    final exportId = JsonCodec.string(created['id']) ?? '';
    if (exportId.isEmpty) {
      return Result.failure(
        ApiError(message: 'Export was created but id was missing.'),
      );
    }

    var status = JsonCodec.stringOr(created['status'], 'queued').toLowerCase();
    for (var attempt = 0; attempt < 25; attempt++) {
      final poll = await _api.get(
        ResidencesEndpoints.reportsExport(exportId),
        silent: true,
      );
      if (poll.isFailure) {
        return Result.failure(
          poll.error ?? const ApiError(message: 'Could not check export status.'),
        );
      }
      final map = JsonCodec.unwrapMap(poll.value);
      status = JsonCodec.stringOr(map['status'], status).toLowerCase();
      if (status == 'ready') {
        return _downloadExportBytes(
          exportId,
          JsonCodec.string(map['fileUrl'] ?? map['downloadUrl']),
        );
      }
      if (status == 'failed') {
        return Result.failure(
          ApiError(message: 'The export failed on the server.'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    return Result.failure(ApiError(message: stillRunningMessage));
  }

  Future<Result<List<int>>> _downloadExportBytes(
    String exportId,
    String? preferredUrl,
  ) async {
    final preferred = (preferredUrl?.trim().isNotEmpty == true)
        ? preferredUrl!.trim()
        : ResidencesEndpoints.reportsExportDownload(exportId);
    final usesSignedToken = preferred.contains('token=');
    try {
      final headers = <String, dynamic>{
        'Accept': 'text/csv, application/octet-stream, */*',
      };
      if (!usesSignedToken) {
        final token = _tokens?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final subdomain = _tenant?.subdomain;
        if (subdomain != null && subdomain.isNotEmpty) {
          headers['X-Tenant-Subdomain'] = subdomain;
        }
      }
      final response = await Dio().get<List<int>>(
        _resolveExportUrl(preferred),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final code = response.statusCode ?? 0;
      final bytes = response.data ?? const <int>[];
      if (code < 200 || code >= 300 || bytes.isEmpty) {
        return Result.failure(
          ApiError(message: 'Could not download the export file.'),
        );
      }
      return Result.success(bytes);
    } catch (_) {
      return Result.failure(
        ApiError(message: 'Could not download the export file.'),
      );
    }
  }

  Future<Result<List<int>>> _buildRosterCsv() async {
    final result = await getResidences();
    if (result.isFailure) {
      return Result.failure(
        result.error ??
            const ApiError(message: 'Could not load residences for export.'),
      );
    }
    final buffer = StringBuffer()
      ..writeln(
        'Residence Name,Address,Type,Service Type,Capacity,Assigned Staff,'
        'Primary Manager,Status,GPS Radius',
      );
    for (final r in result.value!) {
      buffer.writeln(
        [
          r.name,
          r.address ?? '—',
          r.residenceType ?? '—',
          r.serviceType ?? '—',
          '${r.residents} / ${r.bedCapacity} Beds',
          '${r.assignedStaffCount} Members',
          r.primaryManager?.name ?? '—',
          r.statusLabel,
          r.gpsRadiusMeters == null ? '—' : '${r.gpsRadiusMeters}m',
        ].map(_csvCell).join(','),
      );
    }
    return Result.success(utf8.encode(buffer.toString()));
  }

  static String _csvCell(String value) {
    final text = value.replaceAll('\r\n', ' ').replaceAll('\n', ' ').trim();
    if (text.contains(',') || text.contains('"')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _resolveExportUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = AppEnv.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('/api/v1/')) {
      return '${base.replaceAll(RegExp(r'/api/v1$'), '')}$trimmed';
    }
    if (trimmed.startsWith('/')) return '$base$trimmed';
    return '$base/$trimmed';
  }

  Result<ResidenceSummary> _residenceResult(
    Result<dynamic> result,
    String fallback,
  ) {
    return result.when(
      success: (body) {
        final residence = ResidencesMapper.residenceFrom(JsonCodec.unwrap(body));
        return residence == null
            ? Result.failure(ApiError(message: fallback))
            : Result.success(residence);
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<void>> _send(Future<Result<dynamic>> request) async {
    final result = await request;
    return result.when(
      success: (_) => Result.success(null),
      failure: (error) => Result.failure(error),
    );
  }
}
