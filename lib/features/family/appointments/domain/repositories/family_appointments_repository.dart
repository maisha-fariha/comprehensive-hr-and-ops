import 'package:gems_core/gems_core.dart';

import '../../../profile_settings/domain/entities/family_linked_client.dart';
import '../entities/family_appointment.dart';

abstract class FamilyAppointmentsRepository {
  Future<Result<List<FamilyAppointment>>> getAppointments();

  Future<Result<List<FamilyLinkedClient>>> getLinkedResidents();

  Future<Result<void>> createAppointment({
    required String type,
    required String clientId,
    required DateTime scheduledAt,
    String location = '',
    String? notes,
  });

  Future<Result<void>> reschedule({
    required String appointmentId,
    required DateTime scheduledAt,
  });

  Future<Result<void>> cancel(String appointmentId);
}
