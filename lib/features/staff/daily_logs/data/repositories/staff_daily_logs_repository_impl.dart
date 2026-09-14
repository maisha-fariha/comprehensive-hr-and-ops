import 'package:dio/dio.dart';
import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/daily_note_attachment.dart';
import '../../domain/entities/daily_note_overview.dart';
import '../../domain/entities/staff_daily_logs_overview.dart';
import '../../domain/repositories/staff_daily_logs_repository.dart';
import '../mappers/staff_daily_logs_mapper.dart';

class StaffDailyLogsRepositoryImpl implements StaffDailyLogsRepository {
  static const _pageLimit = 20;

  final AppApiClient _api;
  final UserSession _session;

  StaffDailyLogsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<StaffDailyLogsOverview>> getOverview() async {
    // My Clients list
    final clients = await _api.get(
      ApiEndpoints.clients,
      query: {
        'assignedToMe': true,
        'page': 1,
        'limit': _pageLimit,
      },
    );
    if (clients.isFailure) {
      return Result.failure(
        clients.error ??
            const ApiError(message: 'Could not load assigned clients.'),
      );
    }

    final clientMaps = JsonCodec.unwrapList(clients.value)
        .whereType<Map>()
        .map(JsonCodec.asMap)
        .toList();

    String? fallbackResidenceId = _session.residenceId;
    if (fallbackResidenceId == null || fallbackResidenceId.isEmpty) {
      for (final json in clientMaps) {
        fallbackResidenceId = JsonCodec.string(
          json['residenceId'] ?? JsonCodec.mapAt(json, 'residence')?['id'],
        );
        if (fallbackResidenceId != null && fallbackResidenceId.isNotEmpty) {
          break;
        }
      }
    }

    final logDate = IsoDateRange.todayDate;
    final draftLogs = <({String clientId, dynamic body})>[];
    final submittedLogs = <({String clientId, dynamic body})>[];

    // In Progress + Submitted tabs filter the day view with entryStatus.
    await Future.wait(
      clientMaps.expand((json) {
        final clientId = JsonCodec.string(json['id']);
        if (clientId == null || clientId.isEmpty) {
          return const <Future<void>>[];
        }
        final residenceId = JsonCodec.string(
              json['residenceId'] ??
                  JsonCodec.mapAt(json, 'residence')?['id'],
            ) ??
            fallbackResidenceId;
        if (residenceId == null || residenceId.isEmpty) {
          return const <Future<void>>[];
        }

        return [
          _fetchDayLog(
            clientId: clientId,
            residenceId: residenceId,
            logDate: logDate,
            entryStatus: 'draft',
            into: draftLogs,
          ),
          _fetchDayLog(
            clientId: clientId,
            residenceId: residenceId,
            logDate: logDate,
            entryStatus: 'submitted',
            into: submittedLogs,
          ),
        ];
      }),
    );

    final flags = await _api.get(
      ApiEndpoints.careFlags,
      query: {
        'page': 1,
        'limit': _pageLimit,
        'state': 'open',
        if (fallbackResidenceId != null && fallbackResidenceId.isNotEmpty)
          'residenceId': fallbackResidenceId,
      },
    );

    return Result.success(
      StaffDailyLogsMapper.compose(
        clientsBody: clients.value,
        draftLogs: draftLogs,
        submittedLogs: submittedLogs,
        flagsBody: flags.isSuccess ? flags.value : const [],
      ),
    );
  }

  Future<void> _fetchDayLog({
    required String clientId,
    required String residenceId,
    required String logDate,
    required String entryStatus,
    required List<({String clientId, dynamic body})> into,
  }) async {
    final result = await _api.get(
      ApiEndpoints.dailyLogs,
      query: {
        'clientId': clientId,
        'residenceId': residenceId,
        'logDate': logDate,
        'entryStatus': entryStatus,
      },
    );
    if (result.isSuccess) {
      into.add((clientId: clientId, body: result.value));
    }
  }

  @override
  Future<Result<DailyNoteOverview>> getEntryDetail(String entryId) async {
    final result = await _api.get(ApiEndpoints.dailyLogEntryById(entryId));
    return result.when(
      success: (body) async =>
          Result.success(StaffDailyLogsMapper.noteFromEntry(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<DailyNoteOverview>> getEmptyDailyNote() async {
    return Result.success(StaffDailyLogsMapper.emptyNote());
  }

  @override
  Future<Result<String>> saveEntry({
    required String clientId,
    required String residenceId,
    required String body,
    String? entryId,
    required bool submit,
    Map<String, String>? observations,
    String? shift,
    bool wellnessCheckCompleted = false,
    bool flagForAttention = false,
    List<DailyNoteAttachment> attachments = const [],
  }) async {
    final status = submit ? 'submitted' : 'draft';
    final observationsPayload = _observationsPayload(observations);
    final attachmentPayload = [
      for (final file in attachments)
        {
          'fileUrl': file.fileUrl,
          'fileType': file.fileType,
        },
    ];
    final resolvedShift = (shift != null && shift.isNotEmpty)
        ? shift
        : _shiftForNow();

    // Save (new draft) → POST with status: draft
    // Submit (new) → POST with status: submitted
    // Edit draft / Submit Note → PATCH existing entry
    if (entryId == null || entryId.isEmpty) {
      final result = await _api.post(
        ApiEndpoints.dailyLogEntries,
        data: {
          'clientId': clientId,
          'residenceId': residenceId,
          'logDate': IsoDateRange.todayDate,
          'body': body,
          'status': status,
          'shift': resolvedShift,
          'wellnessCheckCompleted': wellnessCheckCompleted,
          // Map treats this as a boolean; only send on submit.
          'flagForAttention': submit && flagForAttention,
          if (observationsPayload != null) 'observations': observationsPayload,
          if (attachmentPayload.isNotEmpty) 'attachments': attachmentPayload,
        },
      );
      return result.when(
        success: (value) async {
          final json = JsonCodec.unwrapMap(value);
          return Result.success(
            JsonCodec.stringOr(json['id'] ?? json['entryId'], ''),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    }

    final result = await _api.patch(
      ApiEndpoints.dailyLogEntryById(entryId),
      data: {
        'body': body,
        'status': status,
        'shift': resolvedShift,
        'wellnessCheckCompleted': wellnessCheckCompleted,
        'flagForAttention': submit && flagForAttention,
        if (observationsPayload != null) 'observations': observationsPayload,
        if (attachmentPayload.isNotEmpty) 'attachments': attachmentPayload,
      },
    );
    return result.when(
      success: (value) async {
        final json = JsonCodec.unwrapMap(value);
        return Result.success(
          JsonCodec.stringOr(json['id'] ?? json['entryId'] ?? entryId, ''),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  Map<String, dynamic>? _observationsPayload(Map<String, String>? observations) {
    if (observations == null || observations.isEmpty) return null;
    final payload = <String, dynamic>{
      if (_nonEmpty(observations['mood']) != null)
        'mood': observations['mood'],
      if (_nonEmpty(observations['meals']) != null)
        'meals': observations['meals'],
      if (_nonEmpty(observations['sleep']) != null)
        'sleep': observations['sleep'],
      if (_nonEmpty(observations['hygiene']) != null)
        'hygiene': observations['hygiene'],
      if (_nonEmpty(observations['activities']) != null)
        'activities': observations['activities'],
      // UI key is `behavior`; API field is `behaviorNotes`.
      if (_nonEmpty(observations['behavior'] ?? observations['behaviorNotes']) !=
          null)
        'behaviorNotes':
            observations['behavior'] ?? observations['behaviorNotes'],
      if (_nonEmpty(observations['wellness']) != null)
        'wellness': observations['wellness'],
    };
    return payload.isEmpty ? null : payload;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Future<Result<String>> amendEntry({
    required String entryId,
    required String body,
    required String reason,
  }) async {
    final result = await _api.post(
      ApiEndpoints.dailyLogAmendments(entryId),
      data: {
        'body': body,
        'reason': reason,
      },
    );
    return result.when(
      success: (value) async {
        final json = JsonCodec.unwrapMap(value);
        return Result.success(
          JsonCodec.stringOr(json['id'] ?? json['entryId'] ?? entryId, ''),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<DailyNoteAttachment>> uploadAttachment({
    required String localPath,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: fileName),
      });
      final result = await _api.post(
        ApiEndpoints.uploads,
        data: form,
        query: const {'category': 'daily-logs'},
        allowQueue: false,
      );
      return result.when(
        success: (body) async {
          final map = JsonCodec.unwrapMap(body);
          final url = JsonCodec.string(
            map['fileUrl'] ?? map['url'] ?? map['publicUrl'],
          );
          if (url == null || url.isEmpty) {
            return Result.failure(
              const ApiError(
                message: 'Upload succeeded but file URL was missing.',
              ),
            );
          }
          final type = JsonCodec.stringOr(
            map['fileType'] ?? map['mimeType'] ?? map['contentType'],
            _fileTypeFromName(fileName),
          );
          return Result.success(
            DailyNoteAttachment(
              fileUrl: url,
              fileType: type,
              fileName: fileName,
            ),
          );
        },
        failure: (error) async => Result.failure(error),
      );
    } catch (error) {
      return Result.failure(
        ApiError(message: 'Could not upload file: $error'),
      );
    }
  }

  @override
  Future<Result<void>> createHandover({
    required String residenceId,
    required String summary,
    String? clientId,
    String? fromShiftId,
    String? toShiftId,
    bool flagForAttention = false,
    bool submit = true,
  }) async {
    final result = await _api.post(
      ApiEndpoints.shiftHandovers,
      data: {
        'residenceId': residenceId,
        'summary': summary,
        'status': submit ? 'submitted' : 'draft',
        if (fromShiftId != null && fromShiftId.isNotEmpty)
          'fromShiftId': fromShiftId,
        if (toShiftId != null && toShiftId.isNotEmpty) 'toShiftId': toShiftId,
        if (clientId != null && clientId.isNotEmpty)
          'clientUpdates': [
            {
              'clientId': clientId,
              'status': flagForAttention ? 'needs_attention' : 'stable',
            },
          ],
        if (flagForAttention) 'flagForAttention': true,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  static String _fileTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'file';
  }

  static String _shiftForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'night';
  }
}
