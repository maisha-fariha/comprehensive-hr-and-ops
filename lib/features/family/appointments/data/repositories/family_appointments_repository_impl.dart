import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/repositories/family_appointments_repository.dart';
import '../mappers/family_appointments_mapper.dart';

class FamilyAppointmentsRepositoryImpl implements FamilyAppointmentsRepository {
  final AppApiClient _api;
  final UserSession _session;

  FamilyAppointmentsRepositoryImpl({
    required AppApiClient api,
    required UserSession session,
  })  : _api = api,
        _session = session;

  @override
  Future<Result<List<FamilyAppointment>>> getAppointments() async {
    final result = await _api.get(
      ApiEndpoints.familyAppointments,
      query: const {'page': 1, 'limit': 20},
    );
    return result.when(
      success: (body) async =>
          Result.success(FamilyAppointmentsMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createAppointment({
    required String type,
    required DateTime scheduledAt,
    required String location,
    String? notes,
  }) async {
    final clientId = _session.selectedClientId;
    final result = await _api.post(
      ApiEndpoints.familyAppointments,
      data: {
        'type': type,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'location': location,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      },
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> reschedule({
    required String appointmentId,
    required DateTime scheduledAt,
  }) async {
    final result = await _api.patch(
      ApiEndpoints.familyAppointmentReschedule(appointmentId),
      data: {'scheduledAt': scheduledAt.toUtc().toIso8601String()},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> cancel(String appointmentId) async {
    final result = await _api.post(
      ApiEndpoints.familyAppointmentCancel(appointmentId),
      data: {},
    );
    return result.when(
      success: (_) async => Result.success(null),
      failure: (error) async => Result.failure(error),
    );
  }
}
