import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/staff_residence.dart';
import '../../domain/entities/staff_shift_handover.dart';
import '../../domain/repositories/staff_extras_repository.dart';
import '../mappers/staff_extras_mapper.dart';

class StaffExtrasRepositoryImpl implements StaffExtrasRepository {
  final AppApiClient _api;
  final UserSession _session;

  StaffExtrasRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<List<StaffShiftHandover>>> getHandovers({
    String? residenceId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final rid = residenceId ?? _session.residenceId;
    final result = await _api.get(
      ApiEndpoints.shiftHandovers,
      query: {
        if (rid != null && rid.isNotEmpty) 'residenceId': rid,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        var items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map((item) => StaffShiftHandover.fromJson(JsonCodec.asMap(item)))
            .where((item) => item.id.isNotEmpty)
            .toList();
        // Local fallback filters when API ignores query params.
        if (from != null || to != null || (status != null && status != 'all')) {
          items = items.where((item) {
            final created = item.createdAt;
            if (from != null && created != null && created.isBefore(from)) {
              return false;
            }
            if (to != null && created != null && created.isAfter(to)) {
              return false;
            }
            if (status != null &&
                status.isNotEmpty &&
                status != 'all' &&
                item.status.toLowerCase() != status.toLowerCase()) {
              return false;
            }
            return true;
          }).toList();
        }
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffShiftHandover>> getHandoverDetail(
    String handoverId,
  ) async {
    final result = await _api.get(ApiEndpoints.handoverById(handoverId));
    return result.when(
      success: (body) async => Result.success(
        StaffShiftHandover.fromJson(StaffExtrasMapper.unwrap(body)),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<String>> createHandover({
    required String residenceId,
    required String summary,
    bool submit = true,
    String? fromShiftId,
    String? toShiftId,
    List<Map<String, dynamic>> pendingActions = const [],
    List<Map<String, dynamic>> clientUpdates = const [],
    Map<String, dynamic>? flagForAttention,
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
        if (pendingActions.isNotEmpty) 'pendingActions': pendingActions,
        if (clientUpdates.isNotEmpty) 'clientUpdates': clientUpdates,
        if (flagForAttention != null) 'flagForAttention': flagForAttention,
      },
    );
    return result.when(
      success: (body) async {
        final json = StaffExtrasMapper.unwrap(body);
        return Result.success(JsonCodec.stringOr(json['id'], ''));
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> acknowledgeHandover({
    required String handoverId,
    String? note,
  }) async {
    final result = await _api.post(
      ApiEndpoints.handoverAcknowledge(handoverId),
      data: {
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> deleteHandover(String handoverId) async {
    final result = await _api.delete(ApiEndpoints.handoverById(handoverId));
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getClientActivities({
    required String clientId,
  }) async {
    final result = await _api.get(
      ApiEndpoints.clientActivities,
      query: {'clientId': clientId},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'activityType',
          subtitleKeys: 'status,notes',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> recordClientActivity({
    required String clientId,
    required String activityType,
    required String status,
    String? notes,
  }) async {
    final result = await _api.post(
      ApiEndpoints.clientActivities,
      data: {
        'clientId': clientId,
        'activityDate': IsoDateRange.todayDate,
        'activityType': activityType,
        'status': status,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getInventoryItems({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _api.get(
      ApiEndpoints.inventoryItems,
      query: {'page': page, 'limit': limit},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'name,sku',
          subtitleKeys: 'quantity,unit,category',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getReferrals() async {
    final result = await _api.get(
      ApiEndpoints.referrals,
      query: const {'page': 1, 'limit': 30},
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'prospectName,name,title',
          subtitleKeys: 'status,stage',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getCourseQuiz(String courseId) async {
    final result = await _api.get(ApiEndpoints.trainingCourseQuiz(courseId));
    return result.when(
      success: (body) async => Result.success(StaffExtrasMapper.unwrap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> submitQuizAttempt({
    required String courseId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final staffId = _session.staffId;
    final result = await _api.post(
      ApiEndpoints.trainingCourseAttempts(courseId),
      data: {
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        'answers': answers,
      },
    );
    return result.when(
      success: (body) async => Result.success(StaffExtrasMapper.unwrap(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getTrainingCertificates() async {
    final result = await _api.get(
      ApiEndpoints.trainingCertificates,
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'courseName,title,name',
          subtitleKeys: 'issuedAt,expiresAt,status',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffResidence>>> getResidences() async {
    final result = await _api.get(ApiEndpoints.residences, silent: true);
    return result.when(
      success: (body) async {
        final residences = StaffExtrasMapper.residencesFrom(body).toList();
        // Always surface the session residence so the module is never empty
        // when the directory call is scoped/empty for this role.
        final sessionId = _session.residenceId;
        final sessionName = _session.residenceName;
        if (sessionName != null &&
            sessionName.isNotEmpty &&
            !residences.any(
              (row) =>
                  row.id == (sessionId ?? '') || row.name == sessionName,
            )) {
          residences.insert(
            0,
            StaffResidence(
              id: sessionId ?? sessionName,
              name: sessionName,
              status: '',
            ),
          );
        }
        return Result.success(residences);
      },
      failure: (error) async {
        final sessionName = _session.residenceName;
        final sessionId = _session.residenceId;
        if (sessionName != null && sessionName.isNotEmpty) {
          return Result.success([
            StaffResidence(
              id: sessionId ?? sessionName,
              name: sessionName,
              status: '',
            ),
          ]);
        }
        return Result.failure(error);
      },
    );
  }

  @override
  Future<Result<StaffResidence>> getResidenceDetail(String residenceId) async {
    final result = await _api.get(ApiEndpoints.residenceById(residenceId));
    return result.when(
      success: (body) async =>
          Result.success(StaffExtrasMapper.residenceFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<int>> getActiveResidentCount() async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {
        'status': 'active',
        'page': '1',
        'limit': '1',
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final meta = JsonCodec.metaOf(body);
        final total = JsonCodec.integer(meta?['total']);
        if (total != null) return Result.success(total);
        return Result.success(JsonCodec.unwrapList(body).length);
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffResidence>> updateResidence({
    required String residenceId,
    required Map<String, dynamic> fields,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.residenceById(residenceId),
      data: fields,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffExtrasMapper.residenceFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffResidence>> deactivateResidence(String residenceId) async {
    return updateResidence(
      residenceId: residenceId,
      fields: const {'status': 'archived'},
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getResidenceClients(
    String residenceId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: {
        'residenceId': residenceId,
        'page': '1',
        'limit': '50',
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final first = JsonCodec.stringOr(json['firstName'], '');
          final last = JsonCodec.stringOr(json['lastName'], '');
          final name = '$first $last'.trim();
          return <String, String>{
            'id': JsonCodec.stringOr(json['id'], ''),
            'title': name.isEmpty ? 'Client' : name,
            'subtitle': JsonCodec.stringOr(
              json['level'] ?? json['roomNumber'],
              '',
            ),
            'status': JsonCodec.stringOr(json['status'], ''),
          };
        }).toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getResidenceRooms(
    String residenceId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.residenceRooms(residenceId),
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'name,roomNumber,number,title',
          subtitleKeys: 'status,beds,bedCount,type',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getResidenceStaffMembers(
    String residenceId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.staff,
      query: {
        'residenceId': residenceId,
        'page': '1',
        'limit': '100',
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final first = JsonCodec.stringOr(json['firstName'], '');
          final last = JsonCodec.stringOr(json['lastName'], '');
          final name = '$first $last'.trim();
          final category = JsonCodec.mapAt(json, 'category');
          return <String, String>{
            'id': JsonCodec.stringOr(json['id'], ''),
            'title': name.isEmpty
                ? JsonCodec.stringOr(json['email'], 'Staff')
                : name,
            'subtitle': JsonCodec.stringOr(
              category?['name'] ?? json['employmentType'] ?? json['email'],
              '',
            ),
            'status': JsonCodec.stringOr(json['status'], ''),
          };
        }).toList(),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getResidenceShifts(
    String residenceId,
  ) async {
    final result = await _api.get(
      ApiEndpoints.shifts,
      query: {
        'residenceId': residenceId,
        'page': '1',
        'limit': '20',
      },
      silent: true,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffExtrasMapper.rowsFrom(
          body,
          titleKeys: 'title,name,shiftType,type',
          subtitleKeys: 'startAt,startsAt,date,status',
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<Map<String, String>>>> getResidenceDailyLogs(
    String residenceId,
  ) async {
    final review = await _api.get(
      ApiEndpoints.dailyLogs,
      query: {
        'residenceId': residenceId,
        'status': 'review',
        'page': '1',
        'limit': '20',
      },
      silent: true,
    );
    final missing = await _api.get(
      ApiEndpoints.dailyLogs,
      query: {
        'residenceId': residenceId,
        'status': 'missing',
        'page': '1',
        'limit': '20',
      },
      silent: true,
    );

    final rows = <Map<String, String>>[];
    void append(dynamic body) {
      for (final item in JsonCodec.unwrapList(body).whereType<Map>()) {
        final json = JsonCodec.asMap(item);
        rows.add({
          'id': JsonCodec.stringOr(
            json['id'] ?? json['clientId'],
            JsonCodec.stringOr(json['logDate'], ''),
          ),
          'title': JsonCodec.stringOr(json['clientName'], 'Client log'),
          'subtitle': JsonCodec.stringOr(json['logDate'], ''),
          'status': JsonCodec.stringOr(json['status'], ''),
        });
      }
    }

    review.when(success: append, failure: (_) {});
    missing.when(success: append, failure: (_) {});

    if (rows.isEmpty &&
        review.isFailure &&
        missing.isFailure) {
      return review.when(
        success: (_) async => Result.success(const []),
        failure: (error) async => Result.failure(error),
      );
    }
    return Result.success(rows);
  }

  @override
  Future<Result<List<StaffResidencePerson>>> getStaffDirectoryOptions() async {
    final result = await _api.get(
      ApiEndpoints.staffDirectory,
      query: const {'page': '1', 'limit': '100'},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final people = JsonCodec.unwrapList(body).whereType<Map>().map((item) {
          final json = JsonCodec.asMap(item);
          final first = JsonCodec.stringOr(json['firstName'], '');
          final last = JsonCodec.stringOr(json['lastName'], '');
          final name = ('$first $last').trim();
          if (name.isEmpty) return null;
          return StaffResidencePerson(
            id: JsonCodec.stringOr(json['id'], name),
            name: name,
            role: JsonCodec.stringOr(
              JsonCodec.mapAt(json, 'category')?['name'],
              '',
            ),
          );
        }).whereType<StaffResidencePerson>().toList(growable: false);
        return Result.success(people);
      },
      failure: (error) async {
        // Fallback to full staff list if directory is unavailable.
        final fallback = await _api.get(
          ApiEndpoints.staff,
          query: const {'page': '1', 'limit': '100'},
          silent: true,
        );
        return fallback.when(
          success: (body) async {
            final people =
                JsonCodec.unwrapList(body).whereType<Map>().map((item) {
              final json = JsonCodec.asMap(item);
              final first = JsonCodec.stringOr(json['firstName'], '');
              final last = JsonCodec.stringOr(json['lastName'], '');
              final name = ('$first $last').trim();
              if (name.isEmpty) return null;
              return StaffResidencePerson(
                id: JsonCodec.stringOr(json['id'], name),
                name: name,
                role: JsonCodec.stringOr(json['employmentType'], ''),
              );
            }).whereType<StaffResidencePerson>().toList(growable: false);
            return Result.success(people);
          },
          failure: (err) async => Result.failure(err),
        );
      },
    );
  }
}
