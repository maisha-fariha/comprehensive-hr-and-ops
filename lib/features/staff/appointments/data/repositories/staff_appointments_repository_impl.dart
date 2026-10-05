import 'package:gems_core/gems_core.dart';

import '../../../../../../core/network/api_endpoints.dart';
import '../../../../../../core/network/app_api_client.dart';
import '../../../../../../core/network/json_codec.dart';
import '../../domain/entities/staff_appointment.dart';
import '../../domain/repositories/staff_appointments_repository.dart';
import '../mappers/staff_appointments_mapper.dart';

class StaffAppointmentsRepositoryImpl implements StaffAppointmentsRepository {
  final AppApiClient _api;

  StaffAppointmentsRepositoryImpl({required AppApiClient api}) : _api = api;

  @override
  Future<Result<StaffAppointmentsSummary>> getSummary() async {
    final result = await _api.get(
      ApiEndpoints.appointmentsSummary,
      silent: true,
    );
    return result.when(
      success: (body) async =>
          Result.success(StaffAppointmentsMapper.summaryFromJson(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffAppointmentsPageResult>> listAppointments({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? search,
  }) async {
    final result = await _api.get(
      ApiEndpoints.appointments,
      query: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
          return StaffAppointmentsMapper.appointmentFromJson(
            JsonCodec.asMap(raw),
          );
        }).toList();
        final meta = JsonCodec.metaOf(body) ?? const {};
        return Result.success(
          StaffAppointmentsPageResult(
            items: items,
            page: JsonCodec.integerOr(meta['page'], page),
            limit: JsonCodec.integerOr(meta['limit'], limit),
            total: JsonCodec.integerOr(meta['total'], items.length),
            totalPages: JsonCodec.integerOr(meta['totalPages'], 1),
          ),
        );
      },
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffAppointment>> createAppointment(
    StaffCreateAppointmentInput input,
  ) async {
    final data = <String, dynamic>{
      'type': input.type,
      'clientId': input.clientId,
      'scheduledAt': input.scheduledAt.toUtc().toIso8601String(),
      if (input.purpose != null && input.purpose!.trim().isNotEmpty)
        'purpose': input.purpose!.trim(),
      if (input.notes != null && input.notes!.trim().isNotEmpty)
        'notes': input.notes!.trim(),
      if (input.location != null && input.location!.trim().isNotEmpty)
        'location': input.location!.trim(),
      if (input.residenceId != null && input.residenceId!.isNotEmpty)
        'residenceId': input.residenceId,
    };
    final result = await _api.post(
      ApiEndpoints.appointments,
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffAppointmentsMapper.appointmentFromJson(
          JsonCodec.unwrapMap(body),
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> approve(String id) async {
    final result = await _api.post(
      ApiEndpoints.appointmentApprove(id),
      data: const <String, dynamic>{},
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reject(String id, {String? reason}) async {
    final result = await _api.post(
      ApiEndpoints.appointmentReject(id),
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> restore(String id) async {
    final result = await _api.post(
      ApiEndpoints.appointmentRestore(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> cancel(String id, {String? reason}) async {
    final result = await _api.post(
      ApiEndpoints.appointmentCancel(id),
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> delete(String id) async {
    final result = await _api.delete(
      ApiEndpoints.appointmentById(id),
      allowQueue: false,
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<StaffAppointment>> updateAppointment(
    String id,
    StaffUpdateAppointmentInput input,
  ) async {
    final data = <String, dynamic>{
      if (input.scheduledAt != null)
        'scheduledAt': input.scheduledAt!.toUtc().toIso8601String(),
      if (input.purpose != null) 'purpose': input.purpose,
      if (input.notes != null) 'notes': input.notes,
      if (input.location != null) 'location': input.location,
      if (input.clientId != null && input.clientId!.isNotEmpty)
        'clientId': input.clientId,
      if (input.residenceId != null && input.residenceId!.isNotEmpty)
        'residenceId': input.residenceId,
    };
    final result = await _api.patch(
      ApiEndpoints.appointmentById(id),
      data: data,
      allowQueue: false,
    );
    return result.when(
      success: (body) async => Result.success(
        StaffAppointmentsMapper.appointmentFromJson(
          JsonCodec.unwrapMap(body),
        ),
      ),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<StaffAppointmentClientOption>>> listClients() async {
    final result = await _api.get(
      ApiEndpoints.clients,
      query: const {'page': 1, 'limit': 200},
      silent: true,
    );
    return result.when(
      success: (body) async {
        final items = JsonCodec.unwrapList(body)
            .whereType<Map>()
            .map(
              (raw) => StaffAppointmentsMapper.clientFromJson(
                JsonCodec.asMap(raw),
              ),
            )
            .where((o) => o.id.isNotEmpty)
            .toList();
        return Result.success(items);
      },
      failure: (error) async => Result.failure(error),
    );
  }
}
