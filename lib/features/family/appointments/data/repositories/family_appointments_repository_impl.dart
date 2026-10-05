import 'package:gems_core/gems_core.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../profile_settings/domain/entities/family_linked_client.dart';
import '../../domain/entities/family_appointment.dart';
import '../../domain/repositories/family_appointments_repository.dart';
import '../mappers/family_appointments_mapper.dart';

class FamilyAppointmentsRepositoryImpl implements FamilyAppointmentsRepository {
  final AppApiClient _api;

  FamilyAppointmentsRepositoryImpl({
    required AppApiClient api,
  }) : _api = api;

  @override
  Future<Result<List<FamilyAppointment>>> getAppointments() async {
    final result = await _api.get(
      ApiEndpoints.familyAppointments,
      query: const {'page': 1, 'limit': 50},
    );
    return result.when(
      success: (body) async =>
          Result.success(FamilyAppointmentsMapper.listFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<List<FamilyLinkedClient>>> getLinkedResidents() async {
    final result = await _api.get(ApiEndpoints.familyClients);
    return result.when(
      success: (body) async =>
          Result.success(FamilyAppointmentsMapper.residentsFrom(body)),
      failure: (error) async => Result.failure(error),
    );
  }

  @override
  Future<Result<void>> createAppointment({
    required String type,
    required String clientId,
    required DateTime scheduledAt,
    String location = '',
    String? notes,
  }) async {
    final result = await _api.post(
      ApiEndpoints.familyAppointments,
      data: {
        'type': type,
        'clientId': clientId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        if (location.trim().isNotEmpty) 'location': location.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
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
    final result = await _api.post(
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
